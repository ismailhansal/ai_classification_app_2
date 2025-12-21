import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';
import 'package:rive_animation/screens/entryPoint/entry_point.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
  });

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController emailController;
late TextEditingController passwordController;


@override
void initState() {
  super.initState();
  emailController = TextEditingController();
  passwordController = TextEditingController();
}

@override
void dispose() {
  emailController.dispose();
  passwordController.dispose();
  super.dispose();
}










  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isShowLoading = false;
  bool isShowConfetti = false;
  late SMITrigger error;
  late SMITrigger success;
  late SMITrigger reset;

  late SMITrigger confetti;

  void _onCheckRiveInit(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');

    artboard.addController(controller!);
    error = controller.findInput<bool>('Error') as SMITrigger;
    success = controller.findInput<bool>('Check') as SMITrigger;
    reset = controller.findInput<bool>('Reset') as SMITrigger;
  }

  void _onConfettiRiveInit(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);

    confetti = controller.findInput<bool>("Trigger explosion") as SMITrigger;
  }

  void singIn(BuildContext context) async {
  setState(() {
    isShowConfetti = true;
    isShowLoading = true;
  });

  // Valider les champs
  if (!_formKey.currentState!.validate()) {
    error.fire();
    setState(() {
      isShowLoading = false;
    });
    reset.fire();
    return;
  }

  try {
    // Connexion avec Firebase Auth
    await _auth.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    // Succès
    success.fire();

    // Attendre un peu pour l’animation
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isShowLoading = false;
    });

    // Confetti
    confetti.fire();

    // Naviguer après 1 seconde
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EntryPoint()),
    );
  } on FirebaseAuthException catch (e) {
    // Erreur Auth
    setState(() {
      isShowLoading = false;
    });
    error.fire();
    reset.fire();

    String message = "Adresse mail ou mot de passe incorrect";
    if (e.code == "user-not-found") {
      message = "Utilisateur non trouvé";
    } else if (e.code == "wrong-password") message = "Mot de passe incorrect";

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Email",
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: TextFormField(
                controller: emailController, // ← ajouté
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Entrez votre email"; // message plus clair
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SvgPicture.asset("assets/icons/emai.svg"),
                  ),
                ),
              ),
            ),
            const Text(
              "Password",
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: TextFormField(
                controller: passwordController, // ← ajouté
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Entrez votre mot de passe"; // message plus clair
                  }
                  return null;
                },
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SvgPicture.asset("assets/icons/passord.svg"),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  singIn(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF09264D),
                  minimumSize: const Size(double.infinity, 56),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                      bottomLeft: Radius.circular(25),
                    ),
                  ),
                ),
                icon: const Icon(
                  CupertinoIcons.arrow_right,
                  color: Color(0xFF09264D),
                ),
                label: const Text("Sign In"),
              ),
            ),
          ],
        ),
      ),
      isShowLoading
          ? CustomPositioned(
              child: RiveAnimation.asset(
                'assets/RiveAssets/check.riv',
                fit: BoxFit.cover,
                onInit: _onCheckRiveInit,
              ),
            )
          : const SizedBox(),
      isShowConfetti
          ? CustomPositioned(
              scale: 6,
              child: RiveAnimation.asset(
                "assets/RiveAssets/confetti.riv",
                onInit: _onConfettiRiveInit,
                fit: BoxFit.cover,
              ),
            )
          : const SizedBox(),
    ],
  );
}

}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, this.scale = 1, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 100,
            width: 100,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
