import 'package:flutter/material.dart';

import 'chatbot_page.dart';

class AnnChatbotPage extends StatelessWidget {
  const AnnChatbotPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return ChatbotPage(
      section: "ANN",
      showAppBar: showAppBar,
    );
  }
}
