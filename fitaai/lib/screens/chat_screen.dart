import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';
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
      duration: AppTheme.mediumDuration,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppTheme.emphasizedCurve,
    ));
    
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppTheme.emphasizedCurve,
    ));
    
    // Start animations after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
    
    // Load user profile and chat history
    _loadUserProfile();
    _loadChatHistory().then((_) {
      // Add welcome message if no history
      if (_messages.isEmpty) {
        setState(() {
          _addBotMessage("Hi there! I'm your AI fitness coach. How can I help you today?");
        });
      }
    });
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

  // Load chat history from Supabase
  Future<void> _loadChatHistory() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    
    try {
      debugPrint('Loading chat history for user: $userId');
      
      // Query chat messages from Supabase
      final data = await supabase
          .from('chat_messages')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(100); // Limit to last 100 messages
      
      debugPrint('Chat history query returned: ${data?.length} messages');
      
      if (data != null && data.isNotEmpty) {
        setState(() {
          // Clear existing messages
          _messages.clear();
          
          // Map the database data to ChatMessage objects
          _messages.addAll(data.map((message) => 
            ChatMessage.fromMap(message)
          ).toList());
        });
        
        // Scroll to bottom after loading messages
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      // Add a message to show there was an error
      setState(() {
        _addBotMessage("I had trouble loading our previous conversations. Let's start a new chat!");
      });
    }
  }

  // Add user message and store in database
  void _addUserMessage(String text) {
    final message = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(message);
    });
    
    // Save message to database
    _saveChatMessage(message);
  }
  
  // Add bot message and store in database
  void _addBotMessage(String text) {
    final message = ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(message);
    });
    
    // Save message to database
    _saveChatMessage(message);
  }
  
  // Save chat message to Supabase
  Future<void> _saveChatMessage(ChatMessage message) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('Cannot save message - user is not logged in');
      return;
    }
    
    try {
      // Skip saving special UI messages
      if (message.text == "__confirmation_buttons__") {
        return;
      }
      
      debugPrint('Saving message to chat_messages table: ${message.text.substring(0, math.min(20, message.text.length))}...');
      
      await supabase.from('chat_messages').insert(message.toMap(userId));
      
      debugPrint('Message saved successfully');
    } catch (e) {
      debugPrint('Error saving chat message: $e');
      // Don't show an error to the user, just log it
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message to state and DB
    _addUserMessage(text);
    _messageController.clear();
    setState(() {
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

    // First check if this might be a plan update request
    _checkForPlanUpdates(userId, text);
  }
  
  // Check if the message is trying to update workout or nutrition plans
  void _checkForPlanUpdates(String userId, String userMessage) {
    // Simple pattern matching to detect potential plan update requests
    final updateKeywords = [
      'update', 'change', 'modify', 'edit', 'replace', 'add',
      'remove', 'delete', 'increase', 'decrease', 'switch',
      'workout', 'exercise', 'nutrition', 'meal', 'diet',
      'calories', 'protein', 'carbs', 'fat', 'macros'
    ];
    
    // Special keywords for instruction updates
    final instructionKeywords = [
      'instruction', 'instructions', 'steps', 'explain', 'clearer',
      'unclear', 'confusing', 'detail', 'details', 'how to', 'guide',
      'form', 'technique', 'perform', 'execution'
    ];
    
    // Health situation keywords
    final healthKeywords = [
      'sick', 'ill', 'injured', 'pain', 'sore', 'tired',
      'exhausted', 'fever', 'cold', 'flu', 'headache',
      'can\'t', 'cannot', 'skip', 'postpone', 'reschedule'
    ];

    // Count how many update keywords are in the message
    int keywordCount = 0;
    for (var keyword in updateKeywords) {
      if (userMessage.toLowerCase().contains(keyword.toLowerCase())) {
        keywordCount++;
      }
    }
    
    // Count instruction keywords
    int instructionKeywordCount = 0;
    for (var keyword in instructionKeywords) {
      if (userMessage.toLowerCase().contains(keyword.toLowerCase())) {
        instructionKeywordCount++;
      }
    }
    
    // Count health situation keywords
    int healthKeywordCount = 0;
    for (var keyword in healthKeywords) {
      if (userMessage.toLowerCase().contains(keyword.toLowerCase())) {
        healthKeywordCount++;
      }
    }

    // Check if this is an instruction update request
    bool isInstructionUpdate = 
        instructionKeywordCount >= 1 && userMessage.toLowerCase().contains('workout') ||
        instructionKeywordCount >= 1 && userMessage.toLowerCase().contains('exercise');
        
    // Check if this is a health-related situation
    bool isHealthSituation = healthKeywordCount >= 1;
    
    // If we have at least 2 update keywords or it's an instruction update or health situation, process accordingly
    if (keywordCount >= 2 || isInstructionUpdate || isHealthSituation) {
      String processMessage = userMessage;
      bool needsConfirmation = false;
      String confirmationMessage = "";
      
      // For instruction updates, modify the message to include special formatting
      if (isInstructionUpdate) {
        // Extract exercise name if mentioned
        String exerciseName = "";
        RegExp exerciseRegex = RegExp(r'for\s+([a-zA-Z\s]+)');
        Match? match = exerciseRegex.firstMatch(userMessage);
        if (match != null && match.groupCount >= 1) {
          exerciseName = match.group(1)?.trim() ?? "";
        }
        
        // Create a JSON-like message structure for better processing
        processMessage = """
        I need clearer instructions for exercises in my workout plan.
        {"updateType": "instructions", "fullPlanUpdate": true, 
         "exerciseName": "$exerciseName", 
         "newInstructions": "Detailed step-by-step instructions with proper form cues and technique guidance."}
        """;
      } 
      // For health situations, format appropriately
      else if (isHealthSituation) {
        needsConfirmation = true;
        confirmationMessage = "I notice you might not be feeling well. Would you like me to suggest modifications to your workout plan for today?";
        
        // We'll handle this with confirmation, so just store the original message
        processMessage = userMessage;
      }
      // For nutrition/macro changes, check if it needs confirmation
      else if (userMessage.toLowerCase().contains('protein') || 
               userMessage.toLowerCase().contains('calories') || 
               userMessage.toLowerCase().contains('carbs') || 
               userMessage.contains('fat')) {
        needsConfirmation = true;
        confirmationMessage = "I understand you want to adjust your nutrition plan. Would you like me to update your macronutrient targets?";
        
        // We'll handle this with confirmation, so just store the original message
        processMessage = userMessage;
      }
      
      // If confirmation is needed, show the confirmation dialog
      if (needsConfirmation) {
        final originalMessage = processMessage;
        
        setState(() {
          _isTyping = false;
          // Add a confirmation message
          _addBotMessage(confirmationMessage);
          // Add confirmation buttons
          _addConfirmationButtons(userId, originalMessage);
        });
      } else {
        // Process request directly if no confirmation needed
        _processUpdateRequest(userId, processMessage);
      }
    } else {
      // If no keywords match, just handle as a regular chat message
      _generateRegularChatResponse(userId, userMessage);
    }
  }
  
  // Add confirmation buttons to the message list
  void _addConfirmationButtons(String userId, String originalMessage) {
    setState(() {
      _messages.add(ChatMessage(
        text: "__confirmation_buttons__", // Special marker for rendering buttons
        isUser: false,
        timestamp: DateTime.now(),
        confirmationData: {
          'userId': userId,
          'message': originalMessage,
        },
      ));
    });
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }
  
  // Process the update request with Gemini
  void _processUpdateRequest(String userId, String message) {
    GeminiService.processUserPlanUpdate(userId, message).then((result) {
      setState(() {
        _isTyping = false;
        
        // If changes were made or it was properly recognized as an update request,
        // respond with the result message
        if (result['success'] == true) {
          _addBotMessage(result['message']);
        } else {
          // If it wasn't recognized as a valid update, fall back to normal chat
          _generateRegularChatResponse(userId, message);
        }
      });
    }).catchError((error) {
      debugPrint('Error processing plan update: $error');
      // Fall back to normal chat response
      _generateRegularChatResponse(userId, message);
    });
  }

  void _generateRegularChatResponse(String userId, String userMessage) {
    GeminiService.generateChatResponse(userId, userMessage).then((response) {
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppTheme.mediumDuration,
        curve: AppTheme.standardCurve,
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
    final colorScheme = Theme.of(context).colorScheme;
    
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
                          color: colorScheme.scrim.withOpacity(0.4 * _animationController.value),
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
                              // Header with app bar
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      onPressed: _closeChat,
                                      tooltip: 'Back',
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Chat with FitCoach',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    ),
                                    const SizedBox(width: 48),
                                    IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed: () {
                                        setState(() {
                                          _messages.clear();
                                          _isTyping = true;
                                        });
                                        _loadChatHistory().then((_) {
                                          setState(() {
                                            _isTyping = false;
                                            if (_messages.isEmpty) {
                                              _addBotMessage("Hi there! I'm your AI fitness coach. How can I help you today?");
                                            }
                                          });
                                        });
                                      },
                                      tooltip: 'Reload chat history',
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Chat messages
                              Expanded(
                                    child: Container(
                                  color: colorScheme.background,
                                      child: _buildChatMessages(),
                                ),
                              ),
                              
                              // Input field
                              Container(
                                    padding: EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                  top: 12,
                                  bottom: MediaQuery.of(context).padding.bottom + 12,
                                    ),
                                    decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, -1),
                                    ),
                                  ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _messageController,
                                            decoration: InputDecoration(
                                              hintText: 'Type your message...',
                                          filled: true,
                                          fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                                              border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(28),
                                                borderSide: BorderSide.none,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(28),
                                            borderSide: BorderSide(
                                              color: colorScheme.outline.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(28),
                                            borderSide: BorderSide(
                                              color: colorScheme.primary,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.chat_bubble_outline,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FloatingActionButton.small(
                                      onPressed: _sendMessage,
                                      elevation: 0,
                                      tooltip: 'Send message',
                                      child: Icon(Icons.send),
                                    ),
                                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    
    // Special case for confirmation buttons
    if (!isUser && message.text == "__confirmation_buttons__") {
      return _buildConfirmationButtons(message.confirmationData!);
    }
    
    // Determine bubble colors based on Material 3 guidelines
    final bubbleColor = isUser
        ? colorScheme.primaryContainer
        : colorScheme.surfaceVariant;
    final textColor = isUser
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  backgroundColor: colorScheme.tertiaryContainer,
                  radius: 16,
                  child: Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  margin: EdgeInsets.only(
                    left: isUser ? 50 : 0,
                    right: isUser ? 0 : 50,
                  ),
                  child: Material(
                    color: bubbleColor,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 20 : 4),
                      topRight: Radius.circular(isUser ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          message.text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  radius: 16,
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4.0,
              left: isUser ? 0 : 40,
              right: isUser ? 40 : 0,
            ),
            child: Text(
              _formatTimestamp(message.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // FitCoach avatar 
          CircleAvatar(
            backgroundColor: colorScheme.tertiaryContainer,
            radius: 16,
                child: Icon(
                  Icons.fitness_center,
              size: 16,
              color: colorScheme.onTertiaryContainer,
                ),
          ),
          const SizedBox(width: 8),
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                  "FitCoach is thinking",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                  width: 60,
                  height: 30,
                  child: _buildThinkingAnimation(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThinkingAnimation() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: BrainwavePainter(
                color: colorScheme.primary,
                animationValue: _animationController.value,
                waveCount: 3,
                amplitude: constraints.maxHeight * 0.4,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            );
          },
        );
      },
    );
  }

  Widget _buildWaveDot(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
              color: colorScheme.primary,
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

  // Build confirmation buttons UI
  Widget _buildConfirmationButtons(Map<String, dynamic> confirmationData) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 8, bottom: 16),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () {
              // Remove the confirmation buttons message
              setState(() {
                _messages.removeWhere((msg) => 
                  !msg.isUser && msg.text == "__confirmation_buttons__");
                _isTyping = true;
              });
              
              // Process the update as confirmed
              _processUpdateRequest(
                confirmationData['userId'], 
                confirmationData['message']
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Yes, update'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              // Remove the confirmation buttons message
              setState(() {
                _messages.removeWhere((msg) => 
                  !msg.isUser && msg.text == "__confirmation_buttons__");
              });
              
              // Send a decline message
              _addBotMessage("I understand. I won't make any changes to your plan. Is there something else I can help you with?");
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.outline),
            ),
            child: const Text('No, thanks'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? confirmationData;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.confirmationData,
  });
  
  // Helper method to create from database record
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['message_text'] as String,
      isUser: map['is_user'] as bool,
      timestamp: DateTime.parse(map['created_at'] as String),
      confirmationData: null,
    );
  }
  
  // Helper method to convert to database record
  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'message_text': text,
      'is_user': isUser,
      'created_at': timestamp.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'ChatMessage(isUser: $isUser, text: "${text.substring(0, math.min(20, text.length))}...", timestamp: $timestamp)';
  }
}

class BrainwavePainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final int waveCount;
  final double amplitude;
  
  BrainwavePainter({
    required this.color,
    required this.animationValue,
    required this.waveCount,
    required this.amplitude,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    
    // Start at the left edge
    path.moveTo(0, centerY);
    
    // Draw the wave pattern
    for (int i = 0; i < waveCount * 2; i++) {
      final x1 = width * (i + 0.5) / (waveCount * 2);
      final x2 = width * (i + 1) / (waveCount * 2);
      
      // Calculate y-offset with animation and alternating peaks/troughs
      final wavePhase = animationValue * 2 * math.pi;
      final yOffset = i.isEven 
          ? amplitude * math.sin(wavePhase)
          : -amplitude * math.sin(wavePhase);
          
      path.quadraticBezierTo(
        x1, centerY + yOffset,
        x2, centerY,
      );
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(BrainwavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color ||
           oldDelegate.amplitude != amplitude ||
           oldDelegate.waveCount != waveCount;
  }
} 