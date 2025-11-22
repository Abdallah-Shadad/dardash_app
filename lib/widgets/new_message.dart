import 'package:flutter/material.dart';

/// Bottom input area used to type and send new messages.
class NewMessage extends StatefulWidget {
  final void Function(String message) onSendMessage;

  const NewMessage({super.key, required this.onSendMessage});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controller = TextEditingController();
  String _enteredMessage = '';

  void _sendMessage() {
    if (_enteredMessage.trim().isEmpty) return;

    widget.onSendMessage(_enteredMessage.trim());
    _controller.clear();
    setState(() => _enteredMessage = '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (value) => setState(() => _enteredMessage = value),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF4F46E5),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _enteredMessage.trim().isEmpty ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
