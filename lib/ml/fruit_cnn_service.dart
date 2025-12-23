import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Service class for CNN fruit classification using TensorFlow Lite
class FruitCnnService {
  static const String _modelPath = 'assets/model/model_frutas_CNN.tflite';
  static const String _labelsPath = 'assets/labels.txt';
  static const int _inputSize = 64; // Model expects 64x64 images
  
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  String? _errorMessage;

  /// Check if the service is initialized and ready
  bool get isInitialized => _isInitialized && _interpreter != null;

  /// Get the current error message if any
  String? get errorMessage => _errorMessage;

  /// Initialize the TensorFlow Lite model and load labels
  /// Returns true if successful, false otherwise
  Future<bool> initialize() async {
    try {
      _errorMessage = null;
      
      // Load labels from assets
      try {
        await _loadLabels();
      } catch (e) {
        throw Exception('Failed to load labels: $e');
      }
      
      // Load model from assets
      ByteData modelData;
      try {
        modelData = await rootBundle.load(_modelPath);
      } catch (e) {
        throw Exception('Failed to load model file from $_modelPath: $e. Make sure the file exists and is declared in pubspec.yaml');
      }
      
      final Uint8List modelBytes = modelData.buffer.asUint8List();
      
      if (modelBytes.isEmpty) {
        throw Exception('Model file is empty');
      }

      // Create interpreter with options
      try {
        _interpreter = Interpreter.fromBuffer(modelBytes);
      } catch (e) {
        throw Exception('Failed to create interpreter: $e');
      }
      
      // Verify model input/output shapes
      if (_interpreter == null) {
        throw Exception('Failed to create interpreter: interpreter is null');
      }

      // Get input and output tensors info
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      if (inputTensors.isEmpty || outputTensors.isEmpty) {
        throw Exception('Invalid model: missing input or output tensors');
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to initialize CNN model: $e';
      _isInitialized = false;
      _interpreter = null;
      _labels = [];
      return false;
    }
  }

  /// Load class labels from assets
  Future<void> _loadLabels() async {
    try {
      final String labelsString = await rootBundle.loadString(_labelsPath);
      _labels = labelsString
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      if (_labels.isEmpty) {
        throw Exception('Labels file is empty');
      }
    } catch (e) {
      throw Exception('Failed to load labels: $e');
    }
  }

  /// Preprocess image to match model input requirements
  /// Resizes to 64x64 and normalizes pixel values to [0, 1]
  Float32List _preprocessImage(img.Image image) {
    // Resize image to 64x64
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to float32 array and normalize to [0, 1]
    final inputBuffer = Float32List(_inputSize * _inputSize * 3);
    int index = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        // In image package 4.x, Pixel object has r, g, b properties
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // Normalize to [0, 1] range
        inputBuffer[index++] = r / 255.0;
        inputBuffer[index++] = g / 255.0;
        inputBuffer[index++] = b / 255.0;
      }
    }

    return inputBuffer;
  }

  /// Run inference on an image file
  /// Returns a JSON-like map with classification results
  Future<Map<String, dynamic>> classifyImage(File imageFile) async {
    if (!isInitialized) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    try {
      // Read and decode image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      return await classifyImageBytes(imageBytes);
    } catch (e) {
      throw Exception('Failed to process image file: $e');
    }
  }

  /// Run inference on image bytes
  /// Returns a JSON-like map with classification results
  Future<Map<String, dynamic>> classifyImageBytes(Uint8List imageBytes) async {
    if (!isInitialized || _interpreter == null) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image bytes');
      }

      // Preprocess image
      final inputBuffer = _preprocessImage(image);

      // Get input/output tensor shapes
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      if (inputTensors.isEmpty || outputTensors.isEmpty) {
        throw Exception('Invalid model structure');
      }

      final inputShape = inputTensors[0].shape;
      final outputShape = outputTensors[0].shape;

      // Prepare input tensor based on model's expected shape
      // Common shapes: [1, 64, 64, 3] or [1, 12288] (flattened)
      dynamic input;
      
      if (inputShape.length == 4) {
        // Shape: [batch, height, width, channels] = [1, 64, 64, 3]
        input = [
          List.generate(
            _inputSize,
            (y) => List.generate(
              _inputSize,
              (x) {
                final baseIndex = (y * _inputSize + x) * 3;
                return [
                  inputBuffer[baseIndex],
                  inputBuffer[baseIndex + 1],
                  inputBuffer[baseIndex + 2],
                ];
              },
            ),
          ),
        ];
      } else if (inputShape.length == 2) {
        // Shape: [batch, flattened] = [1, 12288]
        input = [inputBuffer.toList()];
      } else {
        // Fallback: use flattened input
        input = [inputBuffer.toList()];
      }

      // Prepare output tensor with correct shape structure
      // The output shape must match exactly what the model expects (e.g., [1, 237])
      dynamic output = _createOutputTensor(outputShape);

      // Run inference
      _interpreter!.run(input, output);

      // Flatten output for parsing
      final flattenedOutput = _flattenOutput(output);

      // Parse output
      return _parseOutput(flattenedOutput, outputShape);
    } catch (e) {
      throw Exception('Inference failed: $e');
    }
  }

  /// Create output tensor with correct shape structure
  dynamic _createOutputTensor(List<int> shape) {
    if (shape.isEmpty) {
      return 0.0;
    }
    
    if (shape.length == 1) {
      // 1D: [237] -> List of 237 zeros
      return List.filled(shape[0], 0.0);
    }
    
    if (shape.length == 2) {
      // 2D: [1, 237] -> List containing one list of 237 zeros
      return [List.filled(shape[1], 0.0)];
    }
    
    // For higher dimensions, create nested structure recursively
    return _createNestedList(shape, 0);
  }

  /// Recursively create nested list structure matching the shape
  dynamic _createNestedList(List<int> shape, int index) {
    if (index == shape.length - 1) {
      return List.filled(shape[index], 0.0);
    }
    return List.generate(
      shape[index],
      (_) => _createNestedList(shape, index + 1),
    );
  }

  /// Flatten nested output tensor to a flat list for parsing
  List<double> _flattenOutput(dynamic output) {
    if (output is List) {
      final result = <double>[];
      for (final item in output) {
        if (item is List) {
          result.addAll(_flattenOutput(item));
        } else if (item is double) {
          result.add(item);
        } else if (item is int) {
          result.add(item.toDouble());
        }
      }
      return result;
    } else if (output is double) {
      return [output];
    } else if (output is int) {
      return [output.toDouble()];
    }
    return [];
  }

  /// Parse model output into structured JSON format
  Map<String, dynamic> _parseOutput(List<double> output, List<int> outputShape) {
    try {
      // Output is already a flat list
      final predictions = output;

      // Find the class with highest probability (argmax)
      int predictedClass = 0;
      double maxProbability = predictions[0];

      for (int i = 1; i < predictions.length; i++) {
        if (predictions[i] > maxProbability) {
          maxProbability = predictions[i];
          predictedClass = i;
        }
      }

      // Apply softmax if needed (if outputs are logits)
      // For now, assuming outputs are probabilities or logits
      final probabilities = _applySoftmax(predictions);

      // Get predicted label
      final predictedLabel = predictedClass < _labels.length
          ? _labels[predictedClass]
          : 'Unknown (Class $predictedClass)';

      // Build structured output
      return {
        'success': true,
        'predicted_label': predictedLabel,
        'confidence': probabilities[predictedClass],
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to parse output: $e',
        'raw_output': output.toString(),
      };
    }
  }


  /// Apply softmax function to convert logits to probabilities
  List<double> _applySoftmax(List<double> logits) {
    // Find max for numerical stability
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    
    // Compute exponentials using math.exp
    final expValues = <double>[];
    for (final x in logits) {
      expValues.add(math.exp(x - maxLogit));
    }
    
    // Compute sum
    final sum = expValues.fold(0.0, (a, b) => a + b);
    
    // Normalize
    final probabilities = <double>[];
    for (final x in expValues) {
      probabilities.add(x / sum);
    }
    
    return probabilities;
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = [];
    _isInitialized = false;
    _errorMessage = null;
  }
}


