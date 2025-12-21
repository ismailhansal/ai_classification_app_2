import 'package:flutter/material.dart';

import 'chatbot_page.dart';

class CnnChatbotPage extends StatelessWidget {
  const CnnChatbotPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return ChatbotPage(
      section: "CNN",
      showAppBar: showAppBar,
    );
  }
}
