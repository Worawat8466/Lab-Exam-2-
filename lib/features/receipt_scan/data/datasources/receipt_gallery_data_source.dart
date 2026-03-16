import 'dart:io';

import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/gallery_receipt_image.dart';

abstract class ReceiptGalleryDataSource {
  Future<bool> requestGalleryAccess();
  Future<List<GalleryReceiptImage>> getCurrentMonthReceiptImages({
    required DateTime anchorDate,
  });
}

class ReceiptGalleryDataSourceImpl implements ReceiptGalleryDataSource {
  const ReceiptGalleryDataSourceImpl();

  @override
  Future<List<GalleryReceiptImage>> getCurrentMonthReceiptImages({
    required DateTime anchorDate,
  }) async {
    final authorized = await requestGalleryAccess();
    if (!authorized) {
      return const [];
    }

    final start = DateTime(anchorDate.year, anchorDate.month, 1);
    final end = DateTime(
      anchorDate.year,
      anchorDate.month + 1,
      1,
    ).subtract(const Duration(milliseconds: 1));

    final filter =
        FilterOptionGroup(
            orders: [
              const OrderOption(type: OrderOptionType.createDate, asc: false),
            ],
          )
          ..containsPathModified = true
          ..createTimeCond = DateTimeCond(min: start, max: end);

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: filter,
      hasAll: true,
    );

    if (paths.isEmpty) {
      return const [];
    }

    final assets = await paths.first.getAssetListPaged(page: 0, size: 300);
    final results = <GalleryReceiptImage>[];

    for (final asset in assets) {
      final file = await asset.file;
      final path = file?.path;
      if (path == null || path.isEmpty) {
        continue;
      }

      results.add(
        GalleryReceiptImage(
          assetId: asset.id,
          localPath: path,
          createdAt: asset.createDateTime,
          width: asset.width,
          height: asset.height,
        ),
      );
    }

    return results;
  }

  @override
  Future<bool> requestGalleryAccess() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      // Desktop platforms do not require runtime media permission in the same way.
      return true;
    }

    var permissionGranted = false;

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      permissionGranted = status.isGranted || status.isLimited;
    } else if (Platform.isAndroid) {
      var status = await Permission.photos.request();
      if (!(status.isGranted || status.isLimited)) {
        status = await Permission.storage.request();
      }
      permissionGranted = status.isGranted || status.isLimited;
    }

    if (!permissionGranted) {
      return false;
    }

    final state = await PhotoManager.requestPermissionExtend();
    return state.hasAccess || state.isAuth;
  }
}
