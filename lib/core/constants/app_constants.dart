class AppConstants {
  // App info
  static const String appName = 'Tiak-Tiak';
  static const String appVersion = '1.0.0';

  // API
  static const String baseUrl = String.fromEnvironment(
    'TIAK_API_BASE_URL',
    defaultValue: 'https://api.tiaktiak.com',
  );
  static const Duration apiTimeout = Duration(seconds: 30);

  // Mapbox
  static const String mapboxAccessToken = String.fromEnvironment(
    'TIAK_MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );
  static const String mapboxStyleUrl = 'mapbox://styles/mapbox/streets-v12';

  // Payment
  static const String waveMerchantId = String.fromEnvironment(
    'TIAK_WAVE_MERCHANT_ID',
    defaultValue: '',
  );
  static const String orangeMoneyMerchantId = String.fromEnvironment(
    'TIAK_OM_MERCHANT_ID',
    defaultValue: '',
  );

  // SignalR
  static const String socketUrl = String.fromEnvironment(
    'TIAK_SOCKET_URL',
    defaultValue: baseUrl,
  );
  // Compat temporaire pour les anciens imports/services.
  static const String signalRUrl = socketUrl;

  // Firebase
  static const String firebaseProjectId = 'tiak-tiak-passenger';

  // Storage keys
  static const String storageUserToken = 'user_token';
  static const String storageUserData = 'user_data';
  static const String storageAppSettings = 'app_settings';

  // Phone format
  static const String phonePrefix = '+221';
  static const String phonePattern = r'^\d{2} \d{3} \d{2} \d{2}$';
  static const String phoneDigitsOnlyPattern = r'^\d{9}$';

  // Pricing
  static const int minimumFareFcfa = 500;
  static const int baseFareFcfa = 300;
  static const int pricePerKmFcfa = 180;

  // Trip settings
  static const Duration driverSearchTimeout = Duration(minutes: 5);
  static const Duration locationUpdateInterval = Duration(seconds: 10);
  static const Duration tripConfirmationTimeout = Duration(minutes: 5);
  static const Duration autoConfirmTimeout = Duration(minutes: 2);

  // GPS validation
  static const double maxDestinationDistance = 150.0; // meters
  static const double minTripCompletionRatio = 0.7;
  static const double minDurationCompletionRatio = 0.6;
  static const double passengerLocationThreshold = 300.0; // meters

  // UI Constants
  static const double borderRadius = 12.0;
  static const double buttonHeight = 56.0;
  static const double inputHeight = 56.0;
  static const double cardElevation = 4.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache durations
  static const Duration pricingCacheDuration = Duration(hours: 1);
  static const Duration weatherCacheDuration = Duration(minutes: 10);
  static const Duration locationCacheDuration = Duration(minutes: 5);
}

class AppStrings {
  // Auth
  static const String enterPhoneNumber = 'Entrez votre numéro';
  static const String phoneNumberHint = 'XX XXX XX XX';
  static const String sendOtp = 'Envoyer le code';
  static const String verifyOtp = 'Vérifier';
  static const String resendOtp = 'Renvoyer';
  static const String otpSent = 'Code envoyé';
  static const String invalidOtp = 'Code invalide';

  // Map
  static const String whereTo = 'Où allez-vous ?';
  static const String currentLocation = 'Position actuelle';
  static const String pickupLocation = 'Lieu de départ';
  static const String dropoffLocation = 'Destination';
  static const String searchLocation = 'Rechercher un lieu...';

  // Trip
  static const String bookRide = 'RÉSERVER';
  static const String cancelTrip = 'Annuler';
  static const String callDriver = 'Appeler';
  static const String searchingDriver = 'Recherche de chauffeur...';
  static const String driverFound = 'Chauffeur trouvé';
  static const String driverArrived = 'Votre chauffeur est arrivé';
  static const String tripStarted = 'Course en cours';
  static const String tripCompleted = 'Course terminée';

  // Payment
  static const String selectPaymentMethod = 'Choisir le paiement';
  static const String payAndBook = 'PAYER ET RÉSERVER';
  static const String wave = 'Wave';
  static const String orangeMoney = 'Orange Money';
  static const String paymentConfirmed = 'Paiement confirmé';
  static const String noCashAccepted = 'Aucun cash accepté sur Tiak-Tiak';

  // Profile
  static const String profile = 'Profil';
  static const String editProfile = 'Modifier le profil';
  static const String name = 'Nom';
  static const String phone = 'Téléphone';
  static const String language = 'Langue';
  static const String french = 'Français';
  static const String wolof = 'Wolof';

  // Common
  static const String confirm = 'Confirmer';
  static const String cancel = 'Annuler';
  static const String ok = 'OK';
  static const String yes = 'Oui';
  static const String no = 'Non';
  static const String save = 'Enregistrer';
  static const String loading = 'Chargement...';
  static const String error = 'Erreur';
  static const String retry = 'Réessayer';
  static const String close = 'Fermer';

  // Errors
  static const String networkError = 'Erreur de connexion';
  static const String locationError = 'Erreur de localisation';
  static const String permissionDenied = 'Permission refusée';
  static const String serviceUnavailable = 'Service indisponible';
}
