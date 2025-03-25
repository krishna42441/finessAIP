import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/ui_components.dart';
import '../services/gemini_service.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  final Widget backgroundContent;
  
  const ChatScreen({
    super.key,
    required this.backgroundContent,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  int _selectedIndex = 4; // Chat tab is selected
  
  // User info
  String? _userName;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _blurAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Start animations after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
    
    // Load user profile
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      // Add initial bot message for non-logged in users
      _addBotMessage(
        "Hi there! I'm FitCoach, your personal fitness assistant. I can help you with your workout plans, nutrition advice, and fitness goals. How can I assist you today?",
      );
      return;
    }
    
    try {
      final userProfile = await supabase
          .from('user_profiles')
          .select('full_name')
          .eq('user_id', userId)
          .single();
      
      setState(() {
        _userName = userProfile['full_name'];
      });
      
      // Add personalized greeting
      String greeting = "Hi";
      if (_userName != null && _userName!.isNotEmpty) {
        greeting += " $_userName";
      }
      greeting += "! I'm FitCoach, your personal fitness assistant. I have access to your complete profile, workout plan, and nutrition details. I can help you track your progress, answer questions about your fitness plan, or provide guidance on nutrition and workouts. How can I assist you today?";
      
      _addBotMessage(greeting);
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // Add default greeting if profile loading fails
      _addBotMessage(
        "Hi there! I'm FitCoach, your personal fitness assistant. I can help you with your workout plans, nutrition advice, and fitness goals. How can I assist you today?",
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
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

    // Get the current user ID
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _isTyping = false;
        _addBotMessage("You need to be logged in to use the chat feature. Please log in and try again.");
      });
      return;
    }

    // Generate response using Gemini
    GeminiService.generateChatResponse(userId, text).then((response) {
      setState(() {
        _isTyping = false;
        _addBotMessage(response);
      });
      
      // Scroll to bottom again after response
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }).catchError((error) {
      setState(() {
        _isTyping = false;
        _addBotMessage("I'm sorry, I encountered an error while processing your request. Please try again later.");
      });
      debugPrint('Error generating chat response: $error');
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

  void _closeChat() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _closeChat();
        return false;
      },
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background content (previous screen)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: widget.backgroundContent,
              ),
            ),
            
            // Animated overlay
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Blurred background
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _blurAnimation.value,
                          sigmaY: _blurAnimation.value,
                        ),
                        child: Container(
                          color: Colors.black.withOpacity(0.3 * _animationController.value),
                        ),
                      ),
                    ),
                    
                    // Chat content
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
                        child: SafeArea(
                          child: Column(
                            children: [
                              // Header with close button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: _closeChat,
                                      tooltip: 'Close chat',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black.withOpacity(0.3),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'Chat with AI',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 48),
                                  ],
                                ),
                              ),
                              
                              // Chat messages
                              Expanded(
                                child: ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.1),
                                      child: _buildChatMessages(),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Input field
                              ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                  child: Container(
                                    padding: EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      top: 8,
                                      bottom: MediaQuery.of(context).padding.bottom + 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _messageController,
                                            decoration: InputDecoration(
                                              hintText: 'Type your message...',
                                              hintStyle: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(20),
                                                borderSide: BorderSide.none,
                                              ),
                                              filled: true,
                                              fillColor: Colors.black.withOpacity(0.3),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                            ),
                                            style: const TextStyle(color: Colors.white),
                                            onSubmitted: (_) => _sendMessage(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.send),
                                          onPressed: _sendMessage,
                                          color: AppTheme.primaryColor,
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black.withOpacity(0.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.15);
    final textColor = isUser
        ? Colors.white
        : Colors.white;
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
                    Icons.fitness_center,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              if (!isUser) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  margin: EdgeInsets.only(
                    left: isUser ? 50 : 0,
                    right: isUser ? 0 : 50,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
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
          // FitCoach avatar with pulse animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2 + _animationController.value * 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "FitCoach is typing",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      height: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildWaveDot(0),
                          _buildWaveDot(1),
                          _buildWaveDot(2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index / 3;
        final offset = math.sin((_animationController.value - delay) * math.pi * 2);
        return Transform.translate(
          offset: Offset(0, offset * 4),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
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