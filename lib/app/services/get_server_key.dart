import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {


   Future<String> serverToken() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];
    final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson({
          "type": "service_account",
          "project_id": "lotteryapp-a5eab",
          "private_key_id": "4042fbedd82ebfa34b771319f97ed6e082542345",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC8Q6lLDy/FwTBg\n20ebiSGh9QFAAYX5mjhBrenHAjhoePDPnIRgr27zYyExxYEoHG28Gu0Z1I6LElz1\nUSQo2McA7y0fsNTXxH728xrqrSbgLaP+SANBlMlN2yQPJgWBSQb6BJjBDpbKPRfa\njyZAH5zDqUqbH5p0CVZ9TlZnfAbljUKYu2nNYBvKIOZxtutpHtvP0gvo6zSb4miW\nsGedXXqw65erDh8vaW9YKnMvm2SeuejPawGK8wqvNSEkOh5oL7HrBG1tHk6yLCOW\npRkCavhT5C5CXxn26UgRVEWd2kPYCOnCNIrJUuYr5AoWjCYCprIL1RMrMfXVSc6P\nQwhr8hIzAgMBAAECggEAIHoFltKwWYtplpPNRwoBeMhkpk989qGBieb/+Jor8+3F\nEPN9rJYm7CqSG91n2e0JixUUCMwvqNMKoTEVrUw0DDe2T4y4Mt6NTnmCj7A+EBcf\nfqqakTIjBeDDWC+lbHeWEgQ/+7HSFmIynrvqC87IQsKOAbOSd+jyeBxO8HwnTmrj\nNV1qj6L1i0lNPobscvRHj33JFtG8nCPn72lEITFzXghKko10P51OYyBsl2tLwFqT\nY1TX2SpTFpmCFDtzn0XJJUJmiy5Fsdvm1SZP3xuIkNkjJpCFH9sQNmzrZ2+Py40m\nJK+sO/1jo+qONLCJKCNYj7N4EBg057vScBPDZp3fdQKBgQD1lcCwo4QOCltwrRDK\nTLVxxkAcRmfH6QtRjq0EoFmgd5JEORtYX4C/aMSEX2Zw0ZXurBppbqgk5qSORKQe\nyW+KUcDarNVqmvRxvR/Itchvb4sWDy/+m7GGUSiJ9T7GWv8WX9oge+pHX+7BmvB+\n/MLSXgimmd6lYHWCR2qfv3I75wKBgQDEP5gZhfC5M+deVe2VISaGIdvsSt/TDTM5\n33zNUyOb63wGeIxln4paWrBhgggRgbTbt9G6W/DE85vHRAtuy9v2kuCZ+QAa63er\nqrCkZoH1J6b6Yn6VHXa6UuCX4naTU2uWC7XuoRvdtKodN1qfbvI5tbNXDflFYocl\ngV4TdNiN1QKBgQC39v8KEuNINT/8LtiGAmJlIRJDXAY//XXKGWvILGoXR5rc2j5+\nu8PRHqUfV+uAFbAPwwJh+k+gnNml7QtYOKMCZW1nIdMY8YytavPVQT8tIsx4sNXO\nD0kzibYpafolUmMFmrXmYYzE/Lr4cp03MxapyWEHk/nxvkkoV2Eq25mx/wKBgQDD\n/m89LlOX44py4IaCpbT/yNkHSE/5S/mZFuZheWLa2XfoToSJCaj3TBNTjrXYJh4m\nQZMn96KiUFmHzSFN6jMoMtA1dkTwnbHKtJHt3qJz4MIW1j9tVRu6QgMkLXwW7v1H\nwTJVvHlEFqa+vwW2rOslT55olwAYl6o5ftYhwFR2cQKBgDmbStYzS4Gjjmf8YDBh\nPy1jiaiuHLh4W21rKJdCYaI01r2hUv0OMe3UNMM9xpGmH2tNt/4AbzP0zEAT+NLD\nv4ZVZ/cd9VDee+ETL6XfFuGAGUHokU6JF8fpA7bSJN2w5G4aR4d8D/OBqamAphQk\n2kbHMTLxdCQ6xigG9MMusug9\n-----END PRIVATE KEY-----\n",
          "client_email": "firebase-adminsdk-fbsvc@lotteryapp-a5eab.iam.gserviceaccount.com",
          "client_id": "107174845323724530456",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40lotteryapp-a5eab.iam.gserviceaccount.com",
          "universe_domain": "googleapis.com"
        }),
        scopes);
    final accessserverkey = client.credentials.accessToken.data;
    return accessserverkey;
  }
}