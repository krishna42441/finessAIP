import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

/// Utility class to set up required database functions and policies in Supabase
class DatabaseSetup {
  final SupabaseClient _supabaseClient;

  DatabaseSetup(this._supabaseClient);

  /// Initialize the database with required SQL functions
  Future<void> initializeDatabase() async {
    try {
      print('Starting database initialization...');
      
      // Read the SQL script from the assets
      final String sqlScript = await rootBundle.loadString('assets/db_setup.sql');
      
      // Split the script into individual statements
      final List<String> statements = _splitSqlStatements(sqlScript);
      
      // Execute each statement
      for (final statement in statements) {
        if (statement.trim().isNotEmpty) {
          try {
            print('Executing SQL statement: ${statement.substring(0, statement.length > 50 ? 50 : statement.length)}...');
            await _supabaseClient.rpc('run_admin_query', params: {'query': statement});
            print('Statement executed successfully');
          } catch (e) {
            print('Error executing statement: $e');
            // Continue with the next statement even if this one fails
          }
        }
      }
      
      print('Database initialization completed');
    } catch (e) {
      print('Error during database initialization: $e');
      rethrow;
    }
  }
  
  /// Helper method to split SQL script into individual statements
  List<String> _splitSqlStatements(String sqlScript) {
    // Simple split by semicolon - might need to be more sophisticated
    // for complex SQL scripts with functions containing semicolons
    List<String> rawStatements = sqlScript.split(';');
    List<String> cleanStatements = [];
    
    for (String statement in rawStatements) {
      String clean = statement.trim();
      if (clean.isNotEmpty) {
        cleanStatements.add('$clean;');
      }
    }
    
    return cleanStatements;
  }
  
  /// Check if the required functions are already installed
  Future<bool> checkDatabaseSetup() async {
    try {
      // Try to call a function that should exist if setup is complete
      final result = await _supabaseClient.rpc('get_user_profile', 
          params: {'p_user_id': _supabaseClient.auth.currentUser?.id ?? 'test'});
      
      // If we get here without an error, the function exists
      return true;
    } catch (e) {
      // Function doesn't exist or other error
      print('Database not properly set up: $e');
      return false;
    }
  }
}

/// Helper function to create the run_admin_query function (requires admin access)
/// This should be run once manually by an admin user
String getAdminSetupScript() {
  return '''
-- This function should be created by an admin user
CREATE OR REPLACE FUNCTION run_admin_query(query text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
DECLARE
    result json;
BEGIN
    -- Execute the query
    EXECUTE query;
    RETURN json_build_object('success', true);
EXCEPTION
    WHEN OTHERS THEN
        -- Return error information as JSON
        RETURN json_build_object(
            'error', SQLERRM,
            'detail', SQLSTATE,
            'query', query
        );
END;
\$\$;
''';
} 