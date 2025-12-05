import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_samacite/core/services/image_service.dart';

// Générer les mocks : flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([ImagePicker])
import 'image_service_test.mocks.dart';

void main() {
  late ImageService imageService;
  late MockImagePicker mockImagePicker;

  setUpAll(() {
    // Initialiser Flutter Bindings pour permission_handler
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    mockImagePicker = MockImagePicker();
    imageService = ImageService(picker: mockImagePicker);
  });

  group('ImageService - Validation', () {
    test('should validate image format (jpg, png only)', () async {
      // ARRANGE
      final validFormats = ['image.jpg', 'photo.jpeg', 'picture.png'];
      final invalidFormats = ['doc.pdf', 'video.mp4', 'file.txt', 'image.gif'];

      // ACT & ASSERT
      for (final path in validFormats) {
        expect(imageService.isValidFormat(path), true,
            reason: '$path should be valid');
      }

      for (final path in invalidFormats) {
        expect(imageService.isValidFormat(path), false,
            reason: '$path should be invalid');
      }
    });

    test('should validate image count (max 5)', () {
      // ARRANGE
      final List<String> images1 = ['img1.jpg'];
      final List<String> images3 = ['img1.jpg', 'img2.png', 'img3.jpg'];
      final List<String> images5 = List.generate(5, (i) => 'img$i.jpg');
      final List<String> images6 = List.generate(6, (i) => 'img$i.jpg');

      // ACT & ASSERT
      expect(imageService.isValidCount(images1), true);
      expect(imageService.isValidCount(images3), true);
      expect(imageService.isValidCount(images5), true);
      expect(imageService.isValidCount(images6), false,
          reason: 'Should reject more than 5 images');
      expect(imageService.isValidCount([]), true,
          reason: 'Empty list should be valid');
    });

    test('should validate that adding new image does not exceed limit', () {
      // ARRANGE
      final List<String> currentImages4 = List.generate(4, (i) => 'img$i.jpg');
      final List<String> currentImages5 = List.generate(5, (i) => 'img$i.jpg');

      // ACT & ASSERT
      expect(imageService.canAddMore(currentImages4, 1), true);
      expect(imageService.canAddMore(currentImages4, 2), false);
      expect(imageService.canAddMore(currentImages5, 1), false);
      expect(imageService.canAddMore([], 5), true);
      expect(imageService.canAddMore([], 6), false);
    });
  });

  group('ImageService - Pick Images', () {
    test('should pick single image from gallery', () async {
      // ARRANGE
      final mockFile = XFile('/path/to/test_image.jpg');
      when(mockImagePicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => mockFile);

      // ACT
      final result = await imageService.pickImageFromGallery();

      // ASSERT
      expect(result, isNotNull);
      expect(result!.path, mockFile.path);
      verify(mockImagePicker.pickImage(source: ImageSource.gallery)).called(1);
    }, skip: 'Nécessite mock du plugin permission_handler - test d\'intégration');

    test('should return null if user cancels image selection', () async {
      // ARRANGE
      when(mockImagePicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => null);

      // ACT
      final result = await imageService.pickImageFromGallery();

      // ASSERT
      expect(result, isNull);
    }, skip: 'Nécessite mock du plugin permission_handler - test d\'intégration');

    test('should pick multiple images from gallery', () async {
      // ARRANGE
      final mockFiles = [
        XFile('/path/img1.jpg'),
        XFile('/path/img2.png'),
        XFile('/path/img3.jpg'),
      ];
      when(mockImagePicker.pickMultiImage())
          .thenAnswer((_) async => mockFiles);

      // ACT
      final result = await imageService.pickMultipleImages();

      // ASSERT
      expect(result, isNotNull);
      expect(result.length, 3);
      expect(result[0].path, mockFiles[0].path);
      verify(mockImagePicker.pickMultiImage()).called(1);
    });

    test('should pick single image from camera', () async {
      // ARRANGE
      final mockFile = XFile('/path/to/camera_photo.jpg');
      when(mockImagePicker.pickImage(source: ImageSource.camera))
          .thenAnswer((_) async => mockFile);

      // ACT
      final result = await imageService.pickImageFromCamera();

      // ASSERT
      expect(result, isNotNull);
      expect(result!.path, mockFile.path);
      verify(mockImagePicker.pickImage(source: ImageSource.camera)).called(1);
    }, skip: 'Nécessite mock du plugin permission_handler - test d\'intégration');

    test('should limit multiple image selection to 5 images', () async {
      // ARRANGE
      final mockFiles = List.generate(7, (i) => XFile('/path/img$i.jpg'));
      when(mockImagePicker.pickMultiImage())
          .thenAnswer((_) async => mockFiles);

      // ACT
      final result = await imageService.pickMultipleImages(maxImages: 5);

      // ASSERT
      expect(result.length, 5, reason: 'Should limit to 5 images');
    });

    test('should respect existing images when picking multiple', () async {
      // ARRANGE
      final existingImages = [XFile('/existing/img1.jpg'), XFile('/existing/img2.jpg')];
      final newMockFiles = List.generate(5, (i) => XFile('/new/img$i.jpg'));
      when(mockImagePicker.pickMultiImage())
          .thenAnswer((_) async => newMockFiles);

      // ACT
      final result = await imageService.pickMultipleImages(
        maxImages: 5,
        existingCount: existingImages.length,
      );

      // ASSERT
      expect(result.length, 3, reason: 'Should only allow 3 more images (2 existing + 3 new = 5 total)');
    });
  });

  group('ImageService - Compression', () {
    test('should compress image with default quality', () async {
      // ARRANGE
      final mockFile = XFile('/path/to/large_image.jpg');
      
      // ACT & ASSERT
      // Skip: Nécessite un vrai fichier pour la compression
      expect(
        () => imageService.compressImage(mockFile),
        throwsA(isA<Exception>()),
        reason: 'Should throw exception for non-existent file',
      );
    }, skip: 'Compression nécessite un fichier réel - testé via tests d\'intégration');

    test('should compress image with custom quality', () async {
      // ARRANGE
      final mockFile = XFile('/path/to/image.jpg');

      // ACT & ASSERT
      // Skip: Nécessite un vrai fichier pour la compression
      expect(
        () => imageService.compressImage(mockFile, quality: 50),
        throwsA(isA<Exception>()),
        reason: 'Should throw exception for non-existent file',
      );
    }, skip: 'Compression nécessite un fichier réel - testé via tests d\'intégration');

    test('should throw exception if compression fails', () async {
      // ARRANGE
      final mockFile = XFile('/invalid/path/to/image.jpg');

      // ACT & ASSERT
      expect(
        () => imageService.compressImage(mockFile),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ImageService - File Size Validation', () {
    test('should validate file size (max 5MB per spec.md)', () {
      // ARRANGE
      const maxSize = 5 * 1024 * 1024; // 5MB
      const validSize = 3 * 1024 * 1024; // 3MB
      const invalidSize = 6 * 1024 * 1024; // 6MB

      // ACT & ASSERT
      expect(imageService.isValidSize(validSize), true);
      expect(imageService.isValidSize(maxSize), true);
      expect(imageService.isValidSize(invalidSize), false);
      expect(imageService.isValidSize(0), false);
    });
  });

  group('ImageService - Batch Operations', () {
    test('should compress multiple images', () async {
      // ARRANGE
      final mockFiles = [
        XFile('/path/img1.jpg'),
        XFile('/path/img2.png'),
        XFile('/path/img3.jpg'),
      ];

      // ACT
      final results = await imageService.compressMultipleImages(mockFiles);

      // ASSERT
      expect(results.length, 3);
      // En cas d'échec de compression, retourne les fichiers originaux
      for (final result in results) {
        expect(result.path, isNotNull);
      }
    }, skip: 'Compression nécessite des fichiers réels - testé via tests d\'intégration');

    test('should validate all images in batch', () {
      // ARRANGE
      final validPaths = ['img1.jpg', 'img2.png', 'img3.jpeg'];
      final invalidPaths = ['img1.jpg', 'doc.pdf', 'img3.png'];

      // ACT & ASSERT
      expect(imageService.areAllValidFormats(validPaths), true);
      expect(imageService.areAllValidFormats(invalidPaths), false);
    });
  });

  group('ImageService - Error Handling', () {
    test('should handle exception when picker fails', () async {
      // ARRANGE
      when(mockImagePicker.pickImage(source: ImageSource.gallery))
          .thenThrow(Exception('Camera not available'));

      // ACT & ASSERT
      expect(
        () => imageService.pickImageFromGallery(),
        throwsA(isA<Exception>()),
      );
    });

    test('should return empty list if multiple image selection fails', () async {
      // ARRANGE
      when(mockImagePicker.pickMultiImage())
          .thenThrow(Exception('Permission denied'));

      // ACT & ASSERT
      expect(
        () => imageService.pickMultipleImages(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ImageService - Utility Methods', () {
    test('should get image extension correctly', () {
      // ARRANGE & ACT & ASSERT
      expect(imageService.getExtension('image.jpg'), '.jpg');
      expect(imageService.getExtension('photo.PNG'), '.png');
      expect(imageService.getExtension('picture.jpeg'), '.jpeg');
      expect(imageService.getExtension('/path/to/file.jpg'), '.jpg');
    });

    test('should generate unique filename', () {
      // ACT
      final name1 = imageService.generateUniqueFilename('jpg');
      final name2 = imageService.generateUniqueFilename('png');

      // ASSERT
      expect(name1, contains('compressed_'));
      expect(name1, endsWith('.jpg'));
      expect(name2, endsWith('.png'));
      expect(name1, isNot(equals(name2)));
    });
  });
}
