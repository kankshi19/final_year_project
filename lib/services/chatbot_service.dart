import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  static const String _apiKey = 'AIzaSyBeBoskGYkhRKdYklXSvH7w-GgzI7iiSUY';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [{'text': userMessage}]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        String rawResponse = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        
        // Remove markdown symbols
        String cleanedResponse = rawResponse
            .replaceAll('**', '')  // Remove bold markdown
            .replaceAll('*', '')   // Remove italic markdown
            .trim();

        return cleanedResponse;
      } else {
        throw Exception('Failed to get response: ${response.body}');
      }
    } catch (e) {
      print('Error in sendMessage: $e');
      return 'Sorry, there was an error processing your request.';
    }
  }
}