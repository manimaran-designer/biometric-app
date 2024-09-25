import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum _SupportState {
  unknown,
  supported,
  unsupported,
}

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final LocalAuthentication localAuthentication = LocalAuthentication();
  _SupportState supportState = _SupportState.unknown;
  bool canCheckBiometric = false;
  List<BiometricType>? availableBiometricTypes;
  String authorized = 'Not Authorized';
  bool isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    localAuthentication.isDeviceSupported().then((bool isSupports) => setState(
          () {
            supportState = isSupports
                ? _SupportState.supported
                : _SupportState.unsupported;
          },
        ));
  }

  Future<void> checkBiometrics() async {
    late bool canCheckBiometrics;
    try {
      canCheckBiometrics = await localAuthentication.canCheckBiometrics;
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      print('error: $e');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      canCheckBiometrics = canCheckBiometrics;
    });
  }

  Future<void> getAvailableBiometrics() async {
    late List<BiometricType> availableBiometrics;

    try {
      availableBiometrics = await localAuthentication.getAvailableBiometrics();
    } on PlatformException catch (e) {
      availableBiometrics = <BiometricType>[];
      print('error: $e');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      availableBiometrics = availableBiometrics;
    });
  }

  Future<void> authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        isAuthenticating = true;
        authorized = 'Authenticating';
      });
      authenticated = await localAuthentication.authenticate(
        localizedReason: 'Let OS determine authntication method',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
      setState(() {
        authenticated = false;
      });
    } on PlatformException catch (e) {
      print('error: $e');
      setState(() {
        isAuthenticating = false;
        authorized = 'Error - ${e.message}';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      authorized = authenticated ? 'Authorized' : 'Not Authorized';
    });
  }

  Future<void> authenticateWithBioMetric() async {
    bool authenticated = false;
    try {
      setState(() {
        isAuthenticating = true;
        authorized = 'Authenticating';
      });
      authenticated = await localAuthentication.authenticate(
        localizedReason:
            'Scan your fingerprint (or face or whatever) to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      setState(() {
        isAuthenticating = false;
        authorized = 'Authenticating';
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        isAuthenticating = false;
        authorized = 'Error - ${e.message}';
      });
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      authorized = authenticated ? 'Authorized' : 'Not Authorized';
    });
  }

  Future<void> cancelAuthentication() async {
    await localAuthentication.stopAuthentication();
    setState(() => isAuthenticating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Biometric',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 30, bottom: 30),
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (supportState == _SupportState.unknown)
                const CircularProgressIndicator()
              else if (supportState == _SupportState.supported)
                const Text('This device is supported!')
              else
                const Text('This device is not supported!'),
              const Divider(height: 50),
              Text('Current State: $authorized'),
              const SizedBox(height: 10),
              if (isAuthenticating)
                ElevatedButton(
                  onPressed: cancelAuthentication,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Cancel Authentication'),
                      Icon(Icons.cancel),
                    ],
                  ),
                )
              else
                Column(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: authenticate,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('Authenticate'),
                          Icon(Icons.perm_device_information),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: authenticateWithBioMetric,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(isAuthenticating
                              ? 'Cancel'
                              : 'Authenticate: biometrics only'),
                          const Icon(Icons.fingerprint),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
