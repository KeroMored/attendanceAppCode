import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';

class DisplayPlayers extends StatefulWidget {
  final String studentID;

  const DisplayPlayers(this.studentID, {super.key});

  @override
  State<DisplayPlayers> createState() => _DisplayPlayersState();
}

class _DisplayPlayersState extends State<DisplayPlayers> {
  List<Map<String, dynamic>> playerData = [];
  List<Map<String, dynamic>> allPlayerData = []; // Store all players for filtering
  Map<String, dynamic>? studentData;
  bool isLoading = false;
  bool hasMoreData = true;
  final int pageSize = 10;
  late ScrollController _scrollController;
  Set<String> purchasingPlayers = {}; // Track which players are being purchased
  String selectedPosition = 'CF'; // Default to CF position

  // Available positions (removed 'الكل')
  final List<String> positions = [
    'GK',
    'RB',
    'LB', 
    'CB1',
    'CB2',
    'RMF',
    'LMF',
    'SS',
    'RWF',
    'LWF',
    'CF',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _getStudentData(); // Fetch student data first
    _getPlayerData(); // Load initial page only
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && hasMoreData && !isLoading) {
      _getPlayerData(); // Load more data when scrolled to the bottom
    }
  }

  void _filterPlayersByPosition(String position) {
    setState(() {
      selectedPosition = position;
      // Clear current data and reset pagination
      playerData.clear();
      allPlayerData.clear();
      hasMoreData = true;
      isLoading = false;
    });
    
    // Load players for the selected position
    _getPlayerData();
  }

  Future<void> _getPlayerData() async {
    if (!mounted || isLoading || !hasMoreData) return; // Prevent multiple calls
    setState(() {
      isLoading = true; // Show loading indicator while fetching data
    });

    try {
      final databases = GetIt.I<appwrite.Databases>();
      
      // Build queries for pagination with position filter
      List<String> queries = [
        appwrite.Query.limit(pageSize),
        appwrite.Query.equal('position', selectedPosition), // Filter by selected position only
      ];
      
      // Add cursor for pagination if we have existing data
      if (allPlayerData.isNotEmpty) {
        queries.add(appwrite.Query.cursorAfter(allPlayerData.last['\$id']));
      }
      
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.playersOfStudentCollectionId,
        queries: queries,
      );

      if (documents.documents.isEmpty) {
        hasMoreData = false; // No more data to load
      } else {
        // Check if studentData is not null and extract player IDs
        List<String> currentPlayers = [];
        if (studentData != null && studentData!['playersOfStudent'] is List) {
          currentPlayers = List<String>.from(studentData!['playersOfStudent'].map((player) {
            if (player is Map<String, dynamic>) {
              return player['\$id'] as String; // Ensure this is a string
            }
            return ''; // Return empty if not a valid map
          })); // Remove empty strings
        }

        // Filter out players that the current user already owns
        final newPlayers = documents.documents
            .map((doc) => doc.data)
            .where((player) => !currentPlayers.contains(player['\$id']))
            .toList();

        // Add to our data stores (no additional filtering needed since query is already filtered)
        allPlayerData.addAll(newPlayers);
        playerData.addAll(newPlayers);
        
   
      }
    } on appwrite.AppwriteException catch (e) {
      print('Error loading player data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  Future<void> _addPlayer(String playerId) async {
    if (!mounted || studentData == null) return;

    // Check if this player is already being purchased
    if (purchasingPlayers.contains(playerId)) return;

    // Add to purchasing set and update UI
    setState(() {
      purchasingPlayers.add(playerId);
    });

    // IMPORTANT: Get fresh student data before making any calculations
    if (mounted) {
      await _getStudentData();
    }
    
    if (!mounted || studentData == null) {
      if (mounted) {
        setState(() {
          purchasingPlayers.remove(playerId);
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل بيانات الطالب')),
        );
      }
      return;
    }

    List<dynamic> currentPlayers = studentData!['playersOfStudent'] ?? [];
    Set<String> currentPlayersSet = currentPlayers.map((player) => player['\$id'] as String).toSet();

    // Check if the player is already owned by the student
    if (currentPlayersSet.contains(playerId)) {
      if (mounted) {
        setState(() {
          purchasingPlayers.remove(playerId);
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('أنت تمتلك اللاعب بالفعل!')),
        );
      }
      return; // Exit the function if the player is already owned
    }

    // Retrieve player's price and position from the existing data (no additional fetch needed)
    final player = allPlayerData.firstWhere((p) => p['\$id'] == playerId);
    final playerPrice = player['price'] ?? 0;
    final currentTotalCoins = studentData!['totalCoins'] ?? 0; // Use fresh data
    final playerPosition = player['position'] ?? '';

    // Get databases instance for later use
    final databases = GetIt.I<appwrite.Databases>();

    // Log the playerId and prices
    print('Adding Player ID: $playerId, Player Price: $playerPrice, Current Total Coins: $currentTotalCoins');

    // Check if the student has enough coins
    if (currentTotalCoins < playerPrice) {
      print('Not enough coins to add this player.');
      if (mounted) {
        setState(() {
          purchasingPlayers.remove(playerId);
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
            backgroundColor: Colors.red,
            content: Row(
              
              children: [
                           Icon(Icons.cancel_presentation, size: 25,color: Colors.white,),

                Text(' مش معاك فلوس تكمل ',style: TextStyle(fontWeight: FontWeight.bold),),
              ],
            )),
        );
      }
      return;
    }

    // Check position limits
    Map<String, int> positionLimits = {
      'GK': 1,
      'RB': 1,
      'LB': 1,
      'CB1': 1,
      'CB2': 1,
      'RMF': 1,
      'LMF': 1,
      'SS': 1,
      'RWF': 1,
      'LWF': 1,
      'CF': 1,
    };

    // Count current players by position
    Map<String, int> currentPositionCount = {};
    for (var player in currentPlayers) {
      String position = player['position'] ?? '';
      currentPositionCount[position] = (currentPositionCount[position] ?? 0) + 1;
    }

    // Check if adding the player exceeds the limit
    if ((currentPositionCount[playerPosition] ?? 0) >= (positionLimits[playerPosition] ?? 0)) {
      if (mounted) {
        setState(() {
          purchasingPlayers.remove(playerId);
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        
        SnackBar(
          backgroundColor: Colors.yellowAccent,
          content: Row(
            children: [
              Icon(Icons.warning, size: 25,color: Colors.black,),
              Text(
                //${positionLimits[playerPosition]}
                ' انت تقدر تمتلك $playerPosition واحد فقط .'
               , style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
            ],
          )),
        );
      }
      return; // Exit if the limit is reached
    }

    // Deduct the player's price from totalCoins
    final newTotalCoins = currentTotalCoins - playerPrice;
    
    print('Transaction Summary:');
    print('- Current Coins: $currentTotalCoins');
    print('- Player Price: $playerPrice');
    print('- New Total Coins: $newTotalCoins');

    // Add the new player ID to the list
    currentPlayers.add({'\$id': playerId, 'position': playerPosition}); // Ensure player ID and position are added correctly    // Update student data with the new list of player IDs and totalCoins
    try {
      await updateStudentData(
        databases,
        widget.studentID,
        currentPlayers, // Updated list of player IDs
        newTotalCoins, // Updated totalCoins
      );

      // Refresh student data first to get updated coin count
      await _getStudentData();
      
      // Remove the purchased player from the current player list immediately
      if (mounted) {
        setState(() {
          playerData.removeWhere((player) => player['\$id'] == playerId);
          allPlayerData.removeWhere((player) => player['\$id'] == playerId);
        });
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.green,
              content: Row(
                children: [
                  Icon(Icons.check_box,size: 25,color: Colors.white,),
                  Text('تمت الصفقة بنجاح ', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              )),
        );
      }
    } on appwrite.AppwriteException catch (e) {
      print('Error in _addPlayer: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('حدث خطأ في شراء اللاعب'),
          ),
        );
      }
    } finally {
      // Remove from purchasing set and reset loading state
      if (mounted) {
        setState(() {
          purchasingPlayers.remove(playerId);
          isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  Future<void> updateStudentData(appwrite.Databases databases, String studentRef, List<dynamic> updatedList, int newTotalCoins) async {
    await databases.updateDocument(
      databaseId: AppwriteServices.databaseId,
      collectionId: AppwriteServices.studentsCollectionId,
      documentId: studentRef,
      data: {
        'playersOfStudent': updatedList,
        'totalCoins': newTotalCoins, // Update totalCoins
      },
    );
  }

  Future<void> _getStudentData() async {
    final databases = GetIt.I<appwrite.Databases>();

    try {
      final studentDocument = await databases.getDocument(
        documentId: widget.studentID,
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
      );
      
      // Update the student data with fresh data from database
      studentData = studentDocument.data;
      
      print('Student Data Updated - Total Coins: ${studentData!["totalCoins"]}');
      print('Student Players Count: ${(studentData!["playersOfStudent"] as List?)?.length ?? 0}');
      
      // Update UI if mounted
      if (mounted) {
        setState(() {});
      }
    } on appwrite.AppwriteException catch (e) {
      print('Error fetching student data: $e');
    }
  }

  Widget _getPlayerImage(Map<String, dynamic> player) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final imageSize = isSmallScreen ? 50.0 : 60.0;
    
    // Get player image URL from the database
    String? imageUrl = player['image'];
    String playerName = player['nameOfPlayer'] ?? 
                       player['name'] ?? 
                       player['playerName'] ?? 
                       'Unknown Player';
    
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
      print('Loading image for $playerName: $imageUrl');
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: imageSize,
        height: imageSize,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: imageSize,
            height: imageSize,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image for player: $playerName - $error');
          return _getDefaultPlayerIcon();
        },
      );
    } else {
      print('No image URL for player: $playerName (URL: $imageUrl)');
      return _getDefaultPlayerIcon();
    }
  }

  Widget _getDefaultPlayerIcon() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final imageSize = isSmallScreen ? 50.0 : 60.0;
    final iconSize = isSmallScreen ? 28.0 : 35.0;
    
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!, width: 1),
      ),
      child: Icon(
        Icons.person,
        size: iconSize,
        color: Colors.grey[600],
      ),
    );
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
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                // Coin display widget with dropdown and update button
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Coin display
                          Flexible(
                            flex: 2,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.monetization_on, 
                                  color: Colors.amber, 
                                  size: isSmallScreen ? 24 : (isMediumScreen ? 27 : 30)
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Flexible(
                                  child: Text(
                                    'الرصيد: ${studentData?['totalCoins'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : (isMediumScreen ? 18 : 20),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          // Position dropdown
                          Flexible(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.025, 
                                vertical: screenHeight * 0.005
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                border: Border.all(color: Colors.blue, width: 1),
                              ),
                              child: DropdownButton<String>(
                                value: selectedPosition,
                                underline: Container(),
                                isExpanded: true,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  size: isSmallScreen ? 16 : 20,
                                ),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    _filterPlayersByPosition(newValue);
                                  }
                                },
                                items: positions.map<DropdownMenuItem<String>>((String position) {
                                  return DropdownMenuItem<String>(
                                    value: position,
                                    child: Text(
                                      position,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : (isMediumScreen ? 14 : 16),
                                        fontWeight: position == selectedPosition ? FontWeight.bold : FontWeight.normal,
                                        color: position == selectedPosition ? Colors.blue : Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      // Filter status display
                      Expanded(
                        child: 
                        ListView.builder(
                          controller: _scrollController,
                          itemCount: playerData.length + (hasMoreData && isLoading ? 1 : 0), // Show loading indicator if more data is being fetched
                          itemBuilder: (context, index) {
                            if (index == playerData.length) {
                              return Center(child: CircularProgressIndicator(color: Colors.white)); // Loading indicator
                            }
                            final player = playerData[index];
                            final imageSize = isSmallScreen ? 50.0 : 60.0;
                            
                            return Card(
                              color: Colors.white.withValues(alpha: 0.95),
                              margin: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.03,
                                  vertical: screenHeight * 0.005,
                                ),
                                leading: Container(
                                  width: imageSize,
                                  height: imageSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    border: Border.all(color: Colors.grey[300]!, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    child: _getPlayerImage(player),
                                  ),
                                ),
                                title: Text(
                                  player['nameOfPlayer'] ?? 
                                  player['name'] ?? 
                                  player['playerName'] ?? 
                                  'Unknown Player',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : (isMediumScreen ? 15 : 16),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: EdgeInsets.only(top: screenHeight * 0.005),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.003,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(screenWidth * 0.015),
                                          border: Border.all(color: Colors.green, width: 1),
                                        ),
                                        child: Text(
                                          '\$${player['price'] ?? '0'}',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : (isMediumScreen ? 12 : 13),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.003,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(screenWidth * 0.015),
                                          border: Border.all(color: Colors.blue, width: 1),
                                        ),
                                        child: Text(
                                          player['position'],
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : (isMediumScreen ? 12 : 13),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: isSmallScreen ? 35 : 40,
                                  height: isSmallScreen ? 35 : 40,
                                  child: purchasingPlayers.contains(player['\$id'])
                                      ? CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                        )
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                            ),
                                            elevation: 3,
                                          ),
                                          child: Icon(
                                            Icons.add_circle, 
                                            color: Colors.white,
                                            size: isSmallScreen ? 16 : 20,
                                          ),
                                          onPressed: () {
                                            var playerId = player['\$id'];
                                            _addPlayer(playerId);
                                          },
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}