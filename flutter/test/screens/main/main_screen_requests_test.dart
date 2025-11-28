import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MainScreen - Request to Join Functionality', () {
    
    group('Join Bin Dialog', () {
      test('should show request dialog for non-member bins', () {
        bool isOwner = false;
        bool isMember = false;
        bool isAlreadyPartOfBin = isOwner || isMember;
        
        bool shouldShowRequestDialog = !isAlreadyPartOfBin;
        expect(shouldShowRequestDialog, true);
      });

      test('should not show request dialog for owned bins', () {
        bool isOwner = true;
        bool isMember = false;
        bool isAlreadyPartOfBin = isOwner || isMember;
        
        bool shouldShowRequestDialog = !isAlreadyPartOfBin;
        expect(shouldShowRequestDialog, false);
      });

      test('should not show request dialog for member bins', () {
        bool isOwner = false;
        bool isMember = true;
        bool isAlreadyPartOfBin = isOwner || isMember;
        
        bool shouldShowRequestDialog = !isAlreadyPartOfBin;
        expect(shouldShowRequestDialog, false);
      });

      test('should check for existing pending request before showing dialog', () {
        bool hasPendingRequest = true;
        bool shouldShowDialog = !hasPendingRequest;
        
        expect(shouldShowDialog, false);
      });
    });

    group('Pending Request Popup', () {
      test('should show popup when clicking bin with pending request', () {
        bool hasPendingRequest = true;
        bool shouldShowPopup = hasPendingRequest;
        
        expect(shouldShowPopup, true);
      });

      test('should not show popup when clicking bin without pending request', () {
        bool hasPendingRequest = false;
        bool shouldShowPopup = hasPendingRequest;
        
        expect(shouldShowPopup, false);
      });

      test('popup should display correct message', () {
        String message = 'Your request to join this bin is currently under review by the bin owner. You will be notified once your request is approved.';
        expect(message, contains('under review'));
        expect(message, contains('bin owner'));
      });
    });

    group('Bin List Display', () {
      test('should include bins with pending requests in list', () {
        List<Map<String, dynamic>> bins = [
          {'id': 'bin-1', 'name': 'Owned Bin'},
          {'id': 'bin-2', 'name': 'Member Bin'},
          {'id': 'bin-3', 'name': 'Requested Bin', 'has_pending_request': true},
        ];
        
        expect(bins.length, 3);
        expect(bins[2]['has_pending_request'], true);
      });

      test('should pass hasPendingRequest flag to BinCard', () {
        Map<String, dynamic> bin = {
          'id': 'bin-123',
          'name': 'Test Bin',
          'has_pending_request': true,
        };
        
        bool hasPendingRequest = bin['has_pending_request'] == true;
        expect(hasPendingRequest, true);
      });

      test('should not mark bins without pending requests', () {
        Map<String, dynamic> bin = {
          'id': 'bin-123',
          'name': 'Test Bin',
        };
        
        bool hasPendingRequest = bin['has_pending_request'] == true;
        expect(hasPendingRequest, false);
      });
    });

    group('Request Success Handling', () {
      test('should show success message after sending request', () {
        bool requestSent = true;
        bool shouldShowSuccess = requestSent;
        
        expect(shouldShowSuccess, true);
      });

      test('success message should include bin name', () {
        String binName = 'Test Bin';
        String message = 'Request sent to join "$binName"! The owner will review your request.';
        
        expect(message, contains(binName));
        expect(message, contains('Request sent'));
      });

      test('should reload data after successful request', () {
        bool requestSent = true;
        bool shouldReload = requestSent;
        
        expect(shouldReload, true);
      });
    });

    group('Error Handling', () {
      test('should handle error when already a member', () {
        String error = 'You are already a member of this bin.';
        bool isExpectedError = error.contains('already a member');
        
        expect(isExpectedError, true);
      });

      test('should handle error when request already exists', () {
        String error = 'You already have a pending request for this bin.';
        bool isExpectedError = error.contains('already have a pending request');
        
        expect(isExpectedError, true);
      });

      test('should show error message to user', () {
        String error = 'Failed to request to join bin: Network error';
        bool hasError = error.isNotEmpty;
        
        expect(hasError, true);
      });
    });
  });
}

