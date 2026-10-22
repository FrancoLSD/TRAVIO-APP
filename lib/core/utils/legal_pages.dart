import 'package:url_launcher/url_launcher.dart';

const termsOfUseUrl = 'https://traviotermsofuse.vercel.app/';
const privacyPolicyUrl = 'https://travioprivicypolicy.vercel.app/';

/// Abre la página dentro de la app con Safari (SFSafariViewController): botón de cerrar y URL visibles,
/// como en design/SCREENS/SETTINGS - TERMS OF USE.png.
Future<void> openTermsOfUse() => _open(termsOfUseUrl);

Future<void> openPrivacyPolicy() => _open(privacyPolicyUrl);

Future<void> _open(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
