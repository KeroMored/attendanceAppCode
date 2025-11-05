import 'package:attendance/helper/constants.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class ConnectivityService {
  bool isConnected = true; // Field to indicate connectivity status

  // Check both network connectivity and internet access
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      // First check if device has network connectivity
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Then check if we can actually reach the internet
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('Internet connectivity check failed: $e');
      return false;
    }
  }

  Future<void> checkConnectivity(BuildContext context, Future<void> action) async {
    final hasInternet = await hasInternetConnection();
    
    if (hasInternet) {
      isConnected = true;
      try {
        await action;
      } catch (e) {
        print('Action failed even with internet: $e');
        isConnected = false;
        _showConnectionError(context);
      }
    } else {
      isConnected = false;
      _showConnectionError(context);
    }
  }

  Future<void> checkConnectivityWithoutActions(BuildContext context) async {
    final hasInternet = await hasInternetConnection();
    
    if (hasInternet) {
      isConnected = true;
      print("Internet connection available");
    } else {
      isConnected = false;
      print("No internet connection");
      _showConnectionError(context);
    }
  }

  void _showConnectionError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        content: Center(
          child: Text(
            'غير متصل بالإنترنت',
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              fontSize: Constants.deviceWidth / 20
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}