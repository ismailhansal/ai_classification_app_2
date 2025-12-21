import 'package:flutter/material.dart';

import 'chatbot_page.dart';

class LstmChatbotPage extends StatelessWidget {
  const LstmChatbotPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return ChatbotPage(
      section: "LSTM",
      showAppBar: showAppBar,
    );
  }
}
