import 'dart:convert';
import 'package:http/http.dart' as http;

class SafetyChatbotService {
  final String apiKey;
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  List<Map<String, String>> conversationHistory = [];
  
  SafetyChatbotService({required this.apiKey});

  Future<String> sendMessage(String message) async {
    try {
      String contextualizedPrompt = '''
You are Eva, a supportive and empathetic AI companion focused on women's safety and well-being. Your personality traits are:
1. Compassionate and understanding - you genuinely care about the user's feelings
2. Professional yet friendly - maintain a warm, conversational tone while being reliable
3. Safety-conscious - always prioritize user safety in your responses
4. Resourceful - provide practical advice and information when needed

Your key responsibilities:
1. Provide immediate support for safety concerns
2. Engage in general conversation to build trust and rapport
3. Offer emotional support and validate feelings
4. Share safety tips and preventive measures when relevant
5. Guide users to professional help or emergency services when necessary

Guidelines for different scenarios:
- For immediate danger: Provide clear emergency instructions and relevant helpline numbers
- For general safety concerns: Offer practical advice and preventive measures
- For emotional support: Listen, validate feelings, and show empathy
- For casual conversation: Engage naturally while gently steering towards safety awareness when appropriate

Current conversation history:
${_formatConversationHistory()}

User message: $message

Remember to maintain context from previous messages and respond naturally while keeping safety as a priority.
''';

      final response = await http.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [{"text": contextualizedPrompt}]
            }
          ],
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_HARASSMENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            }
          ],
          "generationConfig": {
            "temperature": 0.8, // Slightly increased for more natural responses
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 1024,
            "stopSequences": ["User:", "Assistant:"] // Prevent the model from continuing the conversation
          }
        }),
      );

      if (response.statusCode == 200) {
        print('API Response: ${response.body}'); // For debugging
        
        final responseData = jsonDecode(response.body);
        String botResponse;
        
        try {
          if (responseData['candidates'] != null && 
              responseData['candidates'].isNotEmpty &&
              responseData['candidates'][0]['content'] != null &&
              responseData['candidates'][0]['content']['parts'] != null &&
              responseData['candidates'][0]['content']['parts'].isNotEmpty) {
            
            botResponse = responseData['candidates'][0]['content']['parts'][0]['text'];
            
            // Clean up the response if it contains any prompt artifacts
            botResponse = _cleanResponse(botResponse);
          } else {
            throw FormatException('Unexpected response structure');
          }
        } catch (e) {
          print('Response parsing error: $e');
          throw FormatException('Failed to parse response');
        }
        
        // Update conversation history
        conversationHistory.add({
          'user': message,
          'bot': botResponse,
        });
        
        // Limit history to last 6 exchanges for better context
        if (conversationHistory.length > 6) {
          conversationHistory.removeAt(0);
        }
        
        return botResponse;
      } else {
        print('API Error Status Code: ${response.statusCode}');
        print('API Error Response: ${response.body}');
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in sendMessage: $e'); // For debugging
      if (e is FormatException) {
        return 'I apologize, but I\'m having trouble understanding. Please try rephrasing your message. Remember, if you\'re in immediate danger, please contact emergency services.';
      }
      return 'I apologize, but I\'m having trouble connecting. If you need immediate assistance, please call emergency services or your local women\'s helpline.';
    }
  }

  String _formatConversationHistory() {
    return conversationHistory
        .map((exchange) => 'User: ${exchange['user']}\nEva: ${exchange['bot']}')
        .join('\n\n');
  }

  String _cleanResponse(String response) {
    // Remove any potential prompt artifacts or system messages
    final cleanedResponse = response
        .replaceAll(RegExp(r'Eva:|Assistant:|AI:|Bot:', caseSensitive: false), '')
        .trim();
    
    // Ensure the response doesn't contain any internal instructions
    final responseLines = cleanedResponse.split('\n')
        .where((line) => !line.toLowerCase().contains('remember to') && 
                        !line.toLowerCase().contains('guidelines for') &&
                        !line.toLowerCase().contains('current conversation'))
        .join('\n');
    
    return responseLines.trim();
  }
}

