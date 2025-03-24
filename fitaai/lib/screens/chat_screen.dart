import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/ui_components.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  int _selectedIndex = 4; // Chat tab is selected

  @override
  void initState() {
    super.initState();
    // Add initial bot message
    _addBotMessage(
      "Welcome to FitAI! I'm your personal fitness assistant. I can help you with workout plans, nutrition advice, and tracking your fitness goals. How can I assist you today?",
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });

    // Simulate typing response
    Future.delayed(const Duration(seconds: 1), () {
      _simulateResponse(text);
    });
  }

  void _simulateResponse(String query) {
    String response;

    if (query.toLowerCase().contains('workout') ||
        query.toLowerCase().contains('exercise')) {
      response =
          "Based on your fitness profile, I recommend a 4-day split focusing on your goal of muscle gain. Your available equipment indicates you have access to a full gym. Here's a sample plan:\n\n1. Monday: Upper body (chest/back)\n2. Tuesday: Lower body (quads/hamstrings)\n3. Thursday: Push (shoulders/triceps)\n4. Friday: Pull (back/biceps)\n\nWould you like me to detail specific exercises for any of these days?";
    } else if (query.toLowerCase().contains('diet') ||
        query.toLowerCase().contains('nutrition') ||
        query.toLowerCase().contains('food')) {
      response =
          "Looking at your dietary preferences and restrictions, I've noticed you're aiming for a high-protein diet. Based on your favorite foods and current calories, I suggest:\n\n• Breakfast: Greek yogurt with berries and nuts\n• Lunch: Grilled chicken salad with quinoa\n• Dinner: Salmon with sweet potato and vegetables\n• Snacks: Protein shake, almonds, or cottage cheese\n\nThis plan supports your goal of muscle gain while respecting your gluten sensitivity.";
    } else if (query.toLowerCase().contains('goal') ||
        query.toLowerCase().contains('progress')) {
      response =
          "You're making great progress toward your fitness goals! In the past month, you've:\n\n• Increased your strength by 15% on major lifts\n• Maintained consistent 4x weekly workouts\n• Improved sleep quality from 6 to 7.5 hours\n• Reduced stress levels from 'High' to 'Medium'\n\nBased on these trends, I suggest focusing on improving your protein intake and adding one more day of recovery-focused activity like yoga or swimming.";
    } else {
      response =
          "I'm here to help with your fitness journey! You can ask me about workout plans, nutrition advice, progress tracking, or any other fitness-related questions. How can I assist with your specific fitness goals today?";
    }

    setState(() {
      _isTyping = false;
      _addBotMessage(response);
    });

    // Scroll to bottom again after response
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _addBotMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: AppTheme.gradientBackground(),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar
                _buildAppBar(),
                
                // Chat messages
                Expanded(
                  child: _buildChatMessages(),
                ),
                
                // Bottom input field
                _buildInputField(),
                
                // Extra padding for the navigation bar
                const SizedBox(height: 64),
              ],
            ),
          ),
          
          // Custom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index != _selectedIndex) {
                  if (index == 0) {
                    // Go to home screen
                    Navigator.of(context).pushReplacementNamed('/home');
                  } else {
                    setState(() => _selectedIndex = index);
                    // Other tabs would be implemented in a real app
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "FitAI Assistant",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  "Your personal fitness coach",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          final message = _messages[index];
          return _buildMessageBubble(message);
        } else {
          // Show typing indicator
          return _buildTypingIndicator();
        }
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final bubbleColor = isUser
        ? AppTheme.primaryColor
        : AppTheme.cardColor;
    final textColor = isUser
        ? Colors.white
        : AppTheme.textPrimary;
    final alignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleAlignment = isUser
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: bubbleAlignment,
            children: [
              if (!isUser)
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  radius: 16,
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              if (!isUser) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
              if (isUser)
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 16,
                  child: const Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 40, right: 40),
            child: Text(
              _formatTimestamp(message.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary.withOpacity(0.6),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            radius: 16,
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildDot(1),
                _buildDot(2),
                _buildDot(3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delay) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.textSecondary.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedOpacity(
          opacity: 0.4,
          duration: Duration(milliseconds: 300 * delay),
          alwaysIncludeSemantics: true,
          curve: Curves.easeInOut,
          child: Container(),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                // Expand message input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Ask about workouts, nutrition, or goals...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                
                // Send button
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: AppTheme.primaryColor,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      // Today, show time only
      return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    } else {
      // Another day, show date and time
      return "${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
} 