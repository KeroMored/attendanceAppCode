class Constants {
  // Session data (populated at runtime)
  static String passwordValue = "";
  static String passwordValueForTeam = "";
  static String className = "";
  static String classId = "";
  static bool isUser = true;
  
  // Note: Hardcoded passwords removed for security
  // Authentication now handled by SecureAppwriteService
  static const logo = "assets/images/LogoAlhan.jpg";
  static const saintMaria = "assets/images/logo.jpg";
  static const pdfImage = "assets/images/pdfImage1.png";
  static const excelImage = "assets/images/excelImage1.png";
  static const scan = "assets/images/scan.jpg";
  static const naqoos = "assets/images/naqoos.png";
  static const users = "assets/images/users.png";
  static const addUser = "assets/images/addUser.png";
  static const team = "assets/images/team.png";
  static const mic = "assets/images/mic.png";
  static const backgroundImage = "assets/images/LogoAlhan.jpg";
  static const uploadExcel = "assets/images/image_excel_rpm.png";
  static const footballStadium = "assets/images/football-stadium.jpg";
  static const coach = "assets/images/coach.jpg";
  static const addPlayer = "assets/images/addPlayer.jpg";
  static const coins = "assets/images/coins.png";
  static const golden = "assets/images/golden.jpg";
  static const eftekad = "assets/images/eftekad.png"; // Add your eftekad icon here
  static const quiz = "assets/images/qu.jpg"; // Temporary quiz icon - replace with quiz.png
  static const verse = "assets/images/verse.png";
  static const result = "assets/images/cup.jpg"; // Temporary quiz icon - replace with quiz.png
  static const pray = "assets/images/pray.jpg"; // Prayer icon
  static const cake = "assets/images/cake.jpg"; // Cake icon
  static const pray_results = "assets/images/calender.jpg"; // Prayer icon
  static const teamClassId = "681f72c87215111b670e";

  static double arrowBackSize=2;
  static double deviceWidth=1;
  static double deviceHeight=1;
  static void setSize(double height,double width){
    deviceWidth=width;
    deviceHeight=height;
    arrowBackSize=width/15;
  }


}

enum PaymentStatus {
  paid,
  unpaid,
  pending,
}
