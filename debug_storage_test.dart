// Debug script to test storage operations
// This file can be used to test the storage functionality

import 'package:flutter/material.dart';
import 'lib/services/web_storage_service.dart';
import 'lib/models/transaction.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WebStorageService.initialize();
  
  print('🧪 Testing Storage Operations...');
  
  // Test 1: Get current transactions
  final existingTransactions = await WebStorageService.getTransactions();
  print('📋 Current transactions in storage: ${existingTransactions.length}');
  
  // Test 2: Add a test transaction
  final testTransaction = Transaction(
    id: const Uuid().v4(),
    amount: 100.0,
    description: 'Debug Test Transaction',
    categoryId: 'test_category',
    date: DateTime.now(),
    type: TransactionType.expense,
    accountId: 'personal',
  );
  
  await WebStorageService.addTransaction(testTransaction);
  print('✅ Test transaction added');
  
  // Test 3: Verify transaction was saved
  final updatedTransactions = await WebStorageService.getTransactions();
  print('📋 Transactions after adding test: ${updatedTransactions.length}');
  
  // Test 4: Show all transactions
  print('\n📋 All transactions:');
  for (final transaction in updatedTransactions) {
    print('- ${transaction.description}: ${transaction.amount} (${transaction.type})');
  }
  
  print('\n🎉 Storage test completed!');
}