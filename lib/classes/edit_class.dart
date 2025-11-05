import 'package:appwrite/appwrite.dart';
import 'package:attendance/classes/add_classes.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';
import '../helper/connectivity_service.dart';
import '../helper/constants.dart';
class EditClass extends StatefulWidget {

  final String id;
  final String name;
  final String church;
  final String usersPass;
  final String adminsPass;
  final PaymentStatus payment; // Add this line


  const EditClass({super.key, required this.name, required this.church, required this.usersPass, required this.adminsPass, required this.id, required this.payment});

  @override
  State<EditClass> createState() => _EditClassState();
}

class _EditClassState extends State<EditClass> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _churchController = TextEditingController();
  final TextEditingController _usersController = TextEditingController();
  final TextEditingController _adminsController = TextEditingController();
  late ConnectivityService _connectivityService;
  PaymentStatus? _paymentStatus;


  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _connectivityService =ConnectivityService();

  }

  void _loadStudentData() async {
    _nameController.text = widget.name ;
    _churchController.text = widget.church ;
    _usersController.text = widget.usersPass	;
    _adminsController.text = widget.adminsPass;
    _paymentStatus = widget.payment;
//    region = widget.region;
  }

  Future<void> _updateStudent()async {
    if (_formKey.currentState!.validate()) {

      final databases = GetIt.I<Databases>();


      try{
        await  databases.updateDocument(
            databaseId: AppwriteServices.databaseId,
            collectionId: AppwriteServices.servicesCollectionId,
            documentId: widget.id,
            data: {
              "name": _nameController.text ,
              "church":_churchController.text,
              "usersPassword": _usersController.text,
              "adminsPassword": _adminsController.text,
              "payment": _paymentStatus.toString().split('.').last,
           //   "payment": ,
            }
        );
        FocusScope.of(context).unfocus();
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => AddClasses(),), (route) => false,);

      }on AppwriteException catch(e)

      {
        print(e);
      }


    }


  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);
    double sizedBoxHeight = MediaQuery.of(context).size.height/30;

  return  Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,

      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: ElevatedButton(

            onPressed:
                () {
              _connectivityService.checkConnectivity(context,  _updateStudent());

            }
            ,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),side: BorderSide(width: 2,color: Colors.white)),
              backgroundColor: Colors.blueGrey,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              textStyle: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),
            ),
            //_updateStudent,
            child: Text("حفظ",style: TextStyle(color: Colors.white),),
          ),
        ),
      ],
      title: Text("تعديل البيانات"),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black,size: Constants.arrowBackSize),
        onPressed: () {
          FocusScope.of(context).unfocus();

          Navigator.pop(context);
        },
      ),
    ),
      body:  SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "الاسم",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يجب ادخال اسم الفصل';
                    }
                    return null;
                  },
                ),

                SizedBox(height: sizedBoxHeight), // Spacing between fields

                // DropdownButtonFormField<String>(
                //   dropdownColor: Colors.white,
                //   value: region,
                //   decoration: InputDecoration(
                //     labelText: "المنطقة",
                //     border: OutlineInputBorder(),
                //     prefixIcon: Icon(Icons.map),
                //   ),
                //   items: ['غير محدد','شرق المحطة', 'غرب', 'بحري', 'قبلي'].map((String value) {
                //     return DropdownMenuItem<String>(
                //
                //
                //       value: value,
                //       child: Text(value),
                //     );
                //   }).toList(),
                //   onChanged: (newValue) {
                //
                //     setState(() {
                //       region = newValue;
                //     });
                //   },
                //
                //   // validator: (value) {
                //   //
                //   //   if ((_addressController.text.isNotEmpty&&(value == null || value.isEmpty)) ) {
                //   //     return 'يجب اختيار منطقة';
                //   //   }
                //   //   return null;
                //   // },
                // ),

            //    SizedBox(height: sizedBoxHeight),
                TextFormField(
                  controller: _churchController,
                  decoration: InputDecoration(
                    labelText: "الكنيسة",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.church),
                  ),
                ),
                SizedBox(height: sizedBoxHeight),
                TextFormField(
                  controller: _usersController,
                  decoration: InputDecoration(
                    labelText: "باسورد مستخدمين",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.text,
                ),
                SizedBox(height: sizedBoxHeight),
                TextFormField(
                  controller: _adminsController,
                  decoration: InputDecoration(
                    labelText: "باسورد خدام",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  keyboardType: TextInputType.text,
                ),
                SizedBox(height: sizedBoxHeight),
                DropdownButtonFormField<PaymentStatus>(
                  initialValue: _paymentStatus,

                  decoration: InputDecoration(
                    labelText: "Payment Status",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: PaymentStatus.values.map((PaymentStatus status) {
                    return DropdownMenuItem<PaymentStatus>(
                      value: status,
                      child: Text(status.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (PaymentStatus? newValue) {
                    setState(() {
                      _paymentStatus = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a payment status';
                    }
                    return null;
                  },
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
