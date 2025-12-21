import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';
import 'package:rive_animation/screens/entryPoint/entry_point.dart';
import 'package:firebase_auth/firebase_auth.dart';



class SignUpForm extends StatefulWidget {
  const SignUpForm({
    super.key,
  });

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController emailController;
  late TextEditingController lastNameController; // nouveau
  late TextEditingController firstNameController; // nouveau


late TextEditingController passwordController;


@override
void initState() {
  super.initState();
  emailController = TextEditingController();
  passwordController = TextEditingController();
  lastNameController = TextEditingController(); // nouveau
  firstNameController = TextEditingController();

}

@override
void dispose() {
  emailController.dispose();
  passwordController.dispose();
  lastNameController.dispose(); // dispose aussi
  firstNameController.dispose();
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

 void signUp(BuildContext context) async {
  setState(() {
    isShowConfetti = true;
    isShowLoading = true;
  });

  if (!_formKey.currentState!.validate()) {
    error.fire();
    setState(() {
      isShowLoading = false;
    });
    reset.fire();
    return;
  }

  try {
    // Création du compte Firebase
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    // Ajouter prénom et nom dans le profil
    await userCredential.user!.updateDisplayName(
      "${firstNameController.text.trim()} ${lastNameController.text.trim()}",
    );

    success.fire();

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isShowLoading = false;
    });

    confetti.fire();

    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EntryPoint()),
    );
  } on FirebaseAuthException catch (e) {
    setState(() {
      isShowLoading = false;
    });
    error.fire();
    reset.fire();

    String message = "Erreur lors de la création du compte";
    if (e.code == "email-already-in-use") {
      message = "Cet email est déjà utilisé";
    } else if (e.code == "weak-password") message = "Mot de passe trop faible";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
              "Prenom",
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: TextFormField(
                controller: firstNameController, // ← ajouté
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Entrez votre prenom"; // message plus clair
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
              "Nom",
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: TextFormField(
                controller: lastNameController, // ← ajouté
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Entrez votre Nom"; // message plus clair
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
                  signUp(context);
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
                label: const Text("Sign Up"),
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
