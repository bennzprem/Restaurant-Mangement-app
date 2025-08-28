// Create a new file: lib/services/chat_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Save chat message to database
  Future<void> saveMessage({
    required String userId,
    required String message,
    required bool isUser,
    String? sessionId,
  }) async {
    try {
      await _supabase.from('chat_messages').insert({
        'user_id': userId,
        'message': message,
        'is_user': isUser,
        'session_id': sessionId ?? _generateSessionId(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving chat message: $e');
      rethrow;
    }
  }

  // Get chat history for user
  Future<List<Map<String, dynamic>>> getChatHistory({
    required String userId,
    String? sessionId,
    int limit = 50,
  }) async {
    try {
      final response = await (sessionId != null
          ? _supabase
              .from('chat_messages')
              .select()
              .eq('user_id', userId)
              .eq('session_id', sessionId)
              .order('created_at', ascending: true)
              .limit(limit)
          : _supabase
              .from('chat_messages')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: true)
              .limit(limit));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching chat history: $e');
      return [];
    }
  }

  // Generate unique session ID
  String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // Get user's recent chat sessions
  Future<List<Map<String, dynamic>>> getChatSessions({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('session_id, created_at, message')
          .eq('user_id', userId)
          .eq('is_user', true)  // Only get user messages to identify sessions
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching chat sessions: $e');
      return [];
    }
  }
}

/* 
SQL to create the chat_messages table in Supabase:

CREATE TABLE chat_messages (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    message TEXT NOT NULL,
    is_user BOOLEAN NOT NULL,
    session_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_session_id ON chat_messages(session_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Create policy so users can only see their own messages
CREATE POLICY "Users can view their own chat messages" ON chat_messages
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own chat messages" ON chat_messages
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Optional: Create a trigger to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_chat_messages_updated_at BEFORE UPDATE
    ON chat_messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
*/