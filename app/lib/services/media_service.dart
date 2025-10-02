import '../models/media.dart';
import 'api_service.dart';

class MediaService {
  final ApiService _apiService;

  MediaService(this._apiService);

  Future<List<Media>> getMediaForSos(int sosId) async {
    try {
      final response = await _apiService.get('/media?sos_id=$sosId'); // Exemplo de endpoint
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Media.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar mídias para SOS $sosId: $e');
      return [];
    }
  }

  Future<bool> associateMediaWithSos(int mediaId, int sosId) async {
    try {
      final response = await _apiService.put(
        '/media/$mediaId',
        data: {'sos_id': sosId},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao associar mídia $mediaId com SOS $sosId: $e');
      return false;
    }
  }
}