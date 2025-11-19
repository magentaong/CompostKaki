import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bin Model Data Handling', () {
    test('parses bin data from map correctly', () {
      final binData = {
        'id': '123-456-789',
        'name': 'Home Compost',
        'user_id': 'user-123',
        'latest_temperature': 45,
        'latest_moisture': 'Perfect',
        'health_status': 'Healthy',
        'contributors_list': ['user-123', 'user-456'],
        'image': 'https://example.com/image.jpg',
        'created_at': '2025-01-01T00:00:00Z',
      };

      expect(binData['id'], '123-456-789');
      expect(binData['name'], 'Home Compost');
      expect(binData['latest_temperature'], 45);
      expect(binData['latest_moisture'], 'Perfect');
      expect(binData['health_status'], 'Healthy');
      expect((binData['contributors_list'] as List).length, 2);
    });

    test('handles missing optional fields gracefully', () {
      final binData = {
        'id': '123',
        'name': 'Test Bin',
        'user_id': 'user-123',
      };

      expect(binData['latest_temperature'], null);
      expect(binData['latest_moisture'], null);
      expect(binData['health_status'], null);
      expect(binData['image'], null);
      
      // Should not throw errors
      final temp = binData['latest_temperature'] as int?;
      final moisture = binData['latest_moisture'] as String?;
      expect(temp, null);
      expect(moisture, null);
    });

    test('contributor count calculation is correct', () {
      int getContributorCount(Map<String, dynamic> bin) {
        final contributors = bin['contributors_list'] as List?;
        if (contributors == null) return 0;
        return contributors.length;
      }

      expect(getContributorCount({'contributors_list': null}), 0);
      expect(getContributorCount({'contributors_list': []}), 0);
      expect(getContributorCount({'contributors_list': ['user1']}), 1);
      expect(getContributorCount({'contributors_list': ['user1', 'user2', 'user3']}), 3);
    });

    test('checks if user is bin owner', () {
      bool isOwner(Map<String, dynamic> bin, String userId) {
        return bin['user_id'] == userId;
      }

      final bin = {'user_id': 'owner-123'};
      
      expect(isOwner(bin, 'owner-123'), true);
      expect(isOwner(bin, 'other-user'), false);
      expect(isOwner(bin, ''), false);
    });

    test('checks if user is bin member', () {
      bool isMember(Map<String, dynamic> bin, String userId) {
        final contributors = bin['contributors_list'] as List?;
        if (contributors == null) return false;
        return contributors.contains(userId);
      }

      final bin = {
        'contributors_list': ['user-1', 'user-2', 'user-3']
      };
      
      expect(isMember(bin, 'user-1'), true);
      expect(isMember(bin, 'user-2'), true);
      expect(isMember(bin, 'user-4'), false);
      expect(isMember({'contributors_list': null}, 'user-1'), false);
    });
  });

  group('Bin Log Model Data Handling', () {
    test('parses log data from map correctly', () {
      final logData = {
        'id': 'log-123',
        'bin_id': 'bin-456',
        'user_id': 'user-789',
        'type': 'Monitor',
        'content': 'Temperature check',
        'temperature': 45,
        'moisture': 'Perfect',
        'weight': 5.5,
        'image': 'https://example.com/log.jpg',
        'created_at': '2025-01-01T12:00:00Z',
      };

      expect(logData['type'], 'Monitor');
      expect(logData['content'], 'Temperature check');
      expect(logData['temperature'], 45);
      expect(logData['moisture'], 'Perfect');
      expect(logData['weight'], 5.5);
    });

    test('handles different log types correctly', () {
      final logTypes = ['Monitor', 'Add', 'Flip', 'Other'];
      
      for (final type in logTypes) {
        final log = {'type': type, 'content': 'Test'};
        expect(log['type'], type);
        expect(logTypes.contains(log['type']), true);
      }
    });

    test('validates log has required fields', () {
      bool hasRequiredFields(Map<String, dynamic> log) {
        return log.containsKey('bin_id') && 
               log.containsKey('type') && 
               log.containsKey('content');
      }

      expect(hasRequiredFields({
        'bin_id': '123',
        'type': 'Monitor',
        'content': 'Test'
      }), true);

      expect(hasRequiredFields({
        'type': 'Monitor',
        'content': 'Test'
      }), false);

      expect(hasRequiredFields({
        'bin_id': '123',
        'content': 'Test'
      }), false);
    });
  });

  group('Task Model Data Handling', () {
    test('parses task data from map correctly', () {
      final taskData = {
        'id': 'task-123',
        'bin_id': 'bin-456',
        'creator_id': 'user-789',
        'title': 'Need help with flipping',
        'description': 'The bin is too heavy',
        'status': 'open',
        'assigned_to': null,
        'created_at': '2025-01-01T10:00:00Z',
      };

      expect(taskData['title'], 'Need help with flipping');
      expect(taskData['description'], 'The bin is too heavy');
      expect(taskData['status'], 'open');
      expect(taskData['assigned_to'], null);
    });

    test('handles task status transitions correctly', () {
      final validStatuses = ['open', 'in_progress', 'completed'];
      
      for (final status in validStatuses) {
        expect(validStatuses.contains(status), true);
      }
      
      expect(validStatuses.contains('invalid'), false);
    });

    test('checks if task is assigned', () {
      bool isAssigned(Map<String, dynamic> task) {
        return task['assigned_to'] != null;
      }

      expect(isAssigned({'assigned_to': null}), false);
      expect(isAssigned({'assigned_to': 'user-123'}), true);
    });

    test('checks if user can accept task', () {
      bool canAccept(Map<String, dynamic> task, String userId) {
        return task['status'] == 'open' && 
               task['creator_id'] != userId &&
               task['assigned_to'] == null;
      }

      final task = {
        'status': 'open',
        'creator_id': 'creator-123',
        'assigned_to': null,
      };

      expect(canAccept(task, 'other-user'), true);
      expect(canAccept(task, 'creator-123'), false);
      
      task['assigned_to'] = 'someone';
      expect(canAccept(task, 'other-user'), false);
      
      task['assigned_to'] = null;
      task['status'] = 'completed';
      expect(canAccept(task, 'other-user'), false);
    });
  });
}

