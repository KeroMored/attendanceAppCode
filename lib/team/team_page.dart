import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';

class TeamPage extends StatefulWidget {
  final String studentId;

  const TeamPage({super.key, required this.studentId});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  List<Map<String, dynamic>> players = []; // List to hold players for the current student
  bool isLoading = true;
  int totalCoins = 0;

  @override
  void initState() {
    super.initState();
    _fetchPlayers(); // Fetch the players when the widget is initialized
  }

  Future<void> _removePlayer(Map<String, dynamic> player) async {
    if (!mounted) return;
    
    final databases = GetIt.I<appwrite.Databases>();

    try {
      final playerPrice = player['price'] as int? ?? 0;
      final playerId = player['id']?.toString() ?? '';
      final playerName = player['name']?.toString() ?? 'Unknown';

      if (playerId.isEmpty) {
        debugPrint("Error: Player ID is empty");
        return;
      }

      debugPrint("Removing player: $playerName (ID: $playerId) with price: $playerPrice");

      // Remove the player from the local list first
      players.removeWhere((p) => p['id'] == playerId);

      // Get current student data
      final studentDocument = await databases.getDocument(
        documentId: widget.studentId,
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
      );

      final currentCoins = studentDocument.data['totalCoins'] as int? ?? 0;
      final updatedCoins = currentCoins + playerPrice; // Return the player's price

      debugPrint("Current Coins: $currentCoins");
      debugPrint("Player Price: $playerPrice");
      debugPrint("Updated Coins: $updatedCoins");

      // Update the student document with new player list and coins
      await databases.updateDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        documentId: widget.studentId,
        data: {
          'playersOfStudent': players.map((p) => {'\$id': p['id'], 'position': p['position']}).toList(),
          'totalCoins': updatedCoins,
        },
      );

      debugPrint("Successfully removed player and updated database");

      // Refresh the players list to ensure consistency
      if (mounted) {
        await _fetchPlayers();
      }
      
    } on appwrite.AppwriteException catch (e) {
      debugPrint("AppwriteException in _removePlayer: ${e.message}");
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في إزالة اللاعب'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Refresh to restore correct state
      if (mounted) {
        await _fetchPlayers();
      }
    } catch (e) {
      debugPrint("General error in _removePlayer: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ غير متوقع'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Refresh to restore correct state
      if (mounted) {
        await _fetchPlayers();
      }
    }
  }

  void _showRemovePlayerDialog(Map<String, dynamic>? player) {
    if (player == null || player.isEmpty || player['name'] == null) {
      // Show alert if no player exists
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.scale,
        title: 'لا يوجد لاعب',
        desc: 'لا يوجد لاعب لإزالته.',
        btnOkText: 'إلغاء',
        btnOkOnPress: () {
          // Dialog automatically closes
        },
      ).show();
    } else {
      final playerName = player['name']?.toString() ?? 'لاعب غير معروف';
      // Show confirmation dialog if a player exists
      AwesomeDialog(
        context: context,
        dialogType: DialogType.question,
        animType: AnimType.scale,
        title: 'إزالة اللاعب',
        desc: 'هل تريد حقاً إزالة $playerName؟',
        btnCancelText: 'لا',
        btnCancelOnPress: () {
          // Dialog automatically closes
        },
        btnOkText: 'نعم',
        btnOkOnPress: () async {
          await _removePlayer(player);
        },
      ).show();
    }
  }
  Future<void> _fetchPlayers() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });
    
    final databases = GetIt.I<appwrite.Databases>();

    try {
      final studentDocument = await databases.getDocument(
        documentId: widget.studentId,
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
      );

      debugPrint("Student document data: ${studentDocument.data}");

      totalCoins = studentDocument.data["totalCoins"] as int? ?? 0;

      // Assuming playersOfStudent contains player IDs and their respective positions
      final playerIds = studentDocument.data['playersOfStudent'] as List<dynamic>? ?? [];
      debugPrint("Player IDs from student document: $playerIds");
      
      if (playerIds.isNotEmpty) {
        players = await _getPlayerDetails(playerIds);
      } else {
        players = [];
        debugPrint("No players found for this student");
      }
      
    } on appwrite.AppwriteException catch (e) {
      debugPrint("AppwriteException in _fetchPlayers: ${e.message}");
      debugPrint("Error code: ${e.code}");
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحميل بيانات الفريق'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("General error in _fetchPlayers: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال بقاعدة البيانات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getPlayerDetails(List<dynamic> playerIds) async {
    final databases = GetIt.I<appwrite.Databases>();
    List<Map<String, dynamic>> playerDetails = [];

    debugPrint("Starting to fetch details for ${playerIds.length} players");

    for (var playerId in playerIds) {
      try {
        // Debug: Print the player ID structure
        debugPrint("Processing player ID: $playerId");
        
        String documentId;
        String position = 'Unknown';
        
        if (playerId is Map && playerId.containsKey('\$id')) {
          documentId = playerId['\$id'];
          position = playerId['position'] ?? 'Unknown';
          debugPrint("Extracted document ID: $documentId, position: $position");
        } else if (playerId is String) {
          documentId = playerId;
          debugPrint("Using string player ID: $documentId");
        } else {
          debugPrint("Invalid player ID format, skipping: $playerId");
          continue;
        }
        
        // Validate the document ID
        if (documentId.isEmpty) {
          debugPrint("Empty document ID, skipping");
          continue;
        }
        
        debugPrint("Fetching player document with ID: $documentId");
        
        final playerDocument = await databases.getDocument(
          documentId: documentId,
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.playersOfStudentCollectionId,
        );

        debugPrint("Successfully fetched player document: ${playerDocument.data}");

        // Handle missing nameOfPlayer field with multiple fallbacks
        String playerName = 'Unknown Player';
        
        if (playerDocument.data.containsKey('nameOfPlayer') && 
            playerDocument.data['nameOfPlayer'] != null && 
            playerDocument.data['nameOfPlayer'].toString().isNotEmpty) {
          playerName = playerDocument.data['nameOfPlayer'].toString();
        } else if (playerDocument.data.containsKey('name') && 
                   playerDocument.data['name'] != null && 
                   playerDocument.data['name'].toString().isNotEmpty) {
          playerName = playerDocument.data['name'].toString();
        } else if (playerDocument.data.containsKey('playerName') && 
                   playerDocument.data['playerName'] != null && 
                   playerDocument.data['playerName'].toString().isNotEmpty) {
          playerName = playerDocument.data['playerName'].toString();
        } else {
          debugPrint("Warning: Player document $documentId missing name field. Available fields: ${playerDocument.data.keys.toList()}");
          playerName = 'Player $position'; // Use position as fallback name
        }

        int price = 0;
        if (playerDocument.data.containsKey('price') && playerDocument.data['price'] != null) {
          if (playerDocument.data['price'] is int) {
            price = playerDocument.data['price'];
          } else if (playerDocument.data['price'] is String) {
            price = int.tryParse(playerDocument.data['price']) ?? 0;
          }
        }

        String imageUrl = '';
        if (playerDocument.data.containsKey('image') && 
            playerDocument.data['image'] != null && 
            playerDocument.data['image'].toString().isNotEmpty) {
          imageUrl = playerDocument.data['image'].toString();
        }

        final playerData = {
          'id': documentId,
          'name': playerName,
          'position': position,
          'price': price,
          'image': imageUrl,
        };

        playerDetails.add(playerData);
        debugPrint("Successfully added player: $playerName at position: $position with price: $price");
        
      } on appwrite.AppwriteException catch (e) {
        debugPrint("AppwriteException for player $playerId:");
        debugPrint("  Message: ${e.message}");
        debugPrint("  Code: ${e.code}");
        debugPrint("  Type: ${e.type}");
        
        // Handle specific error cases
        if (e.code == 404) {
          debugPrint("  Player document not found - may have been deleted");
        } else if (e.code == 400 && (e.message?.contains('Invalid document structure') == true)) {
          debugPrint("  Document structure invalid - continuing with next player");
        }
        
        // Skip this player and continue with the next one
        continue;
      } catch (e) {
        debugPrint("Unexpected error for player $playerId: $e");
        continue;
      }
    }

    debugPrint("Finished processing players. Successfully loaded: ${playerDetails.length} out of ${playerIds.length}");
    return playerDetails;
  }

  Widget _getDefaultPlayerIcon([double? width, double? height, double? borderRadius]) {
    final iconWidth = width ?? 42;
    final iconHeight = height ?? 52;
    final iconBorderRadius = borderRadius ?? 8;
    final iconSize = iconWidth * 0.43; // Proportional icon size
    final fontSize = iconWidth * 0.14; // Proportional font size
    
    return Container(
      width: iconWidth,
      height: iconHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[300]!, Colors.grey[400]!],
        ),
        borderRadius: BorderRadius.circular(iconBorderRadius),
        border: Border.all(color: Colors.grey[500]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add,
            size: iconSize,
            color: Colors.grey[600],
          ),
          if (fontSize >= 5) // Only show text if font size is readable
            Text(
              'لاعب',
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // Add refresh functionality
  Future<void> _refreshTeam() async {
    await _fetchPlayers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث الفريق بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage(Constants.footballStadium),
            ),
          ),
        ),
        Column(
          children: [
            // Enhanced coin display with refresh button
            Container(
              margin: EdgeInsets.only(
                top: screenHeight * 0.025, 
                right: screenWidth * 0.04, 
                left: screenWidth * 0.04
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Coin display - moved to left
                  Flexible(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03, 
                        vertical: screenHeight * 0.01
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        border: Border.all(color: Colors.amber, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: isSmallScreen ? 24 : (isMediumScreen ? 28 : 30),
                            child: Image.asset(Constants.coins),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Flexible(
                            child: Text(
                              "$totalCoins",
                              style: TextStyle(
                                color: Colors.amber[800],
                                fontSize: isSmallScreen ? 16 : (isMediumScreen ? 18 : 20),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  // Refresh button - moved to right
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(screenWidth * 0.035),
                    child: InkWell(
                      onTap: _refreshTeam,
                      borderRadius: BorderRadius.circular(screenWidth * 0.035),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(screenWidth * 0.035),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: Colors.blue,
                          size: isSmallScreen ? 16 : (isMediumScreen ? 18 : 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.025),
                      isLoading ? CircularProgressIndicator(color: Colors.white,) : _buildFormation(),
                      SizedBox(height: screenHeight * 0.025),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          // Front line - Wingers and Center Forward
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerButton('RWF'), // RWF
              _buildPlayerButton('CF'),  // CF
              _buildPlayerButton('LWF'),  // LWF
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          // Midfield line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerButton('RMF'), // Right Midfielder
              _buildPlayerButton('SS'), // Second Striker
              _buildPlayerButton('LMF'), // Left Midfielder
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          // Defense line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerButton('RB'), // RB
              _buildPlayerButton('CB1'), // CB
              _buildPlayerButton('CB2'), // CB
              _buildPlayerButton('LB'), // LB
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          // Goalkeeper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerButton('GK'), // GK
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerButton(String position) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    
    final player = players.firstWhere(
          (p) => p['position'] == position,
      orElse: () => {}, // Return an empty map if no player exists
    );

    bool hasPlayer = player.isNotEmpty;
    
    // Responsive sizing
    final buttonWidth = isSmallScreen ? 50.0 : (isMediumScreen ? 70.0 : 80.0);
    final buttonHeight = isSmallScreen ? 65.0 : (isMediumScreen ? 90.0 : 100.0);
    final imageWidth = isSmallScreen ? 40.0 : (isMediumScreen ? 50.0 : 60.0);
    final imageHeight = isSmallScreen ? 40.0 : (isMediumScreen ? 60.0 : 70.0);
    final borderRadius = isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 12.0);
    final nameFontSize = isSmallScreen ? 6.0 : (isMediumScreen ? 6.5 : 7.0);
    final positionFontSize = isSmallScreen ? 4.0 : (isMediumScreen ? 4.5 : 5.0);
    final iconSize = isSmallScreen ? 18.0 : (isMediumScreen ? 20.0 : 22.0);
    
    return Flexible(
      child: Container(
        margin: EdgeInsets.all(screenWidth * 0.005),
        child: Material(
          elevation: hasPlayer ? 6 : 3,
          borderRadius: BorderRadius.circular(borderRadius),
          shadowColor: hasPlayer ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          child: InkWell(
            onTap: () {
              _showRemovePlayerDialog(player.isEmpty ? null : player);
            },
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              width: buttonWidth,
              height: buttonHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: hasPlayer 
                      ? [Colors.white, Colors.blue[50]!]
                      : [Colors.grey[50]!, Colors.grey[100]!],
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: hasPlayer ? Colors.blue[300]! : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Player image or add icon
                  Container(
                    width: imageWidth,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius * 0.67),
                      boxShadow: hasPlayer ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ] : [],
                    ),
                    child: hasPlayer 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadius * 0.67),
                            child: Image.network(
                              player['image']?.toString() ?? '',
                              fit: BoxFit.cover,
                              width: imageWidth,
                              height: imageHeight,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: imageWidth,
                                  height: imageHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(borderRadius * 0.67),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blue,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return _getDefaultPlayerIcon(imageWidth, imageHeight, borderRadius * 0.67);
                              },
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(borderRadius * 0.67),
                              border: Border.all(color: Colors.grey[400]!, width: 1),
                            ),
                            child: Icon(
                              Icons.add_circle_outline,
                              size: iconSize,
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                  SizedBox(height: screenHeight * 0.002),
                  // Player name or position
                  SizedBox(
                    width: buttonWidth - 5,
                    child: Text(
                      hasPlayer ? (player['name']?.toString() ?? position) : position,
                      style: TextStyle(
                        color: hasPlayer ? Colors.black87 : Colors.grey[600],
                        fontSize: nameFontSize,
                        fontWeight: hasPlayer ? FontWeight.bold : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Position indicator for players
                  if (hasPlayer) ...[
                    SizedBox(height: screenHeight * 0.001),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        position,
                        style: TextStyle(
                          fontSize: positionFontSize,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}