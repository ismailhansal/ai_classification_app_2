import 'package:flutter/material.dart';

import 'chatbot_page.dart';

class RagChatbotPage extends StatelessWidget {
  const RagChatbotPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return ChatbotPage(
      section: "RAG",
      showAppBar: showAppBar,
    );
  }
}
