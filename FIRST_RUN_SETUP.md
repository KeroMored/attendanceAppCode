# 🔧 First Run Setup Instructions

## 🚨 IMPORTANT: One-Time Setup

Your app is now configured to automatically set up credentials and add your password to the database on the first run.

### **Step 1: Run the App (First Time Only)**

1. **Run the app once** - this will:
   - ✅ Configure Appwrite credentials securely
   - ✅ Add password '469369219' to database
   - ✅ Set up all necessary security configurations

### **Step 2: After First Successful Run**

Once you see the message "✅ Password 469369219 added to database!" in the console, **immediately** comment out or remove the password setup code:

**Edit `lib/main.dart` and comment out lines 59-65:**

```dart
// **ADD YOUR PASSWORD TO DATABASE (RUN ONCE ONLY)**
// Uncomment and run once, then comment out or delete:

/*
await SecureAppwriteService.addPasswordToDatabase(
  className: 'كنيسة العذراء الصاغة',
  userPassword: '469369219',    // Your password as user
  adminPassword: '469369219',   // Your password as admin  
);
print('✅ Password 469369219 added to database!');
*/
```

### **Step 3: Why This Is Important**

- ✅ **Security**: Prevents duplicate password entries
- ✅ **Performance**: Avoids unnecessary database calls
- ✅ **Clean Code**: Removes setup code after initialization

### **🎯 Expected Flow:**

#### **First Run:**
```
🔐 Configuring credentials...
✅ Credentials configured successfully
🔐 Initializing Appwrite services...
✅ Password 469369219 added to database!
🔔 Notifications initialized
📱 App ready for use!
```

#### **Subsequent Runs:**
```
🔐 Loading existing credentials...
✅ Secure credentials loaded
🔐 Initializing Appwrite services...
📱 App ready for use!
```

### **🚨 If You Get Errors:**

1. **"Duplicate key error"**: Password already exists - comment out the setup code
2. **"Network error"**: Check internet connection
3. **"Permission denied"**: Check Appwrite project settings

### **✅ After Setup Complete:**

- ✅ Your app will work normally
- ✅ Login with password '469369219' will work
- ✅ All security features active
- ✅ No more credential setup needed

**Remember: Comment out the password setup code after first successful run!** 🔐