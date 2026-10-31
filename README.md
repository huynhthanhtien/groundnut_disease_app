# Bệnh Lạc — nhận diện bệnh cây lạc từ ảnh

[![CI](https://github.com/huynhthanhtien/groundnut_disease_app/actions/workflows/ci.yml/badge.svg)](https://github.com/huynhthanhtien/groundnut_disease_app/actions/workflows/ci.yml)
[![Release](https://github.com/huynhthanhtien/groundnut_disease_app/actions/workflows/release.yml/badge.svg)](https://github.com/huynhthanhtien/groundnut_disease_app/actions/workflows/release.yml)

Ứng dụng Flutter (Android) chụp/chọn ảnh lá hoặc quả lạc, nhận diện bệnh bằng
mô hình YOLOv8 xuất sang TFLite (chạy hoàn toàn trên máy, không cần mạng), và
đưa ra hướng dẫn xử lý.

## Tải về và cài đặt

Bản phát hành mới nhất:
**<https://github.com/huynhthanhtien/groundnut_disease_app/releases/latest>**

1. Mở link trên bằng điện thoại Android.
2. Tải file `groundnut-disease-app-<phiên bản>-universal.apk` (cài được trên mọi
   máy). Máy 64-bit có thể dùng bản `arm64-v8a` nhẹ hơn, máy 32-bit cũ dùng bản
   `armeabi-v7a`.
3. Mở file vừa tải. Nếu Android hỏi, bật **"Cài đặt ứng dụng không rõ nguồn
   gốc"** cho trình duyệt hoặc ứng dụng quản lý file, rồi chọn **Cài đặt**.
4. Các bản sau cài đè lên bản cũ được (giữ nguyên lịch sử quét) vì mọi bản phát
   hành đều ký bằng cùng một khóa.

Yêu cầu: Android 7.0 (API 24) trở lên. File `SHA256SUMS.txt` trong mỗi bản phát
hành để kiểm tra file tải về.

## Tính năng

- **Quét**: chụp ảnh hoặc chọn từ thư viện → khung vùng bệnh trên ảnh, tên bệnh
  tiếng Việt, độ tin cậy, mức lan ước tính. Kết quả dưới 50% hiện là
  "Chưa chắc chắn" kèm mẹo chụp lại. Nếu ảnh có thêm bệnh khác đủ tin cậy
  (vd. gỉ sắt cùng đốm lá), mục "Cũng phát hiện trên ảnh" liệt kê và dẫn sang
  cách xử lý từng bệnh.
- **Bệnh hại**: thư viện 6 nhóm bệnh model nhận diện được — triệu chứng, dễ nhầm
  với, điều kiện phát sinh, cần làm ngay, hoạt chất tham khảo, phòng ngừa, khi
  nào gọi chuyên gia.
- **Lịch sử**: lưu kết quả (kèm ghi chú ruộng/luống, sửa được sau) trên máy,
  lọc, tìm theo ghi chú/tên bệnh (gõ không dấu cũng được), vuốt để xóa.
- Chia sẻ ảnh kết quả có khung bệnh; phóng to ảnh; gọi trạm khuyến nông (số do
  người dùng nhập).

## Cấu trúc

```
lib/
  data/disease_info.dart      Nội dung bệnh (tiếng Việt) + mẹo chụp + miễn trừ
  services/
    yolo_model_service.dart   Tải model, chạy suy luận trên isolate nền
    image_preprocessor.dart   Letterbox 640x640 → Float32List NCHW
    yolo_postprocess.dart     Giải mã output [1, 10, 8400] + NMS
    scan_analysis.dart        Kết quả chính, ngưỡng tin cậy, độ phủ, mức lan
    history_store.dart        Lịch sử lưu ở <documents>/history (JSON + ảnh)
    app_settings.dart         Onboarding, số trạm khuyến nông
  screens/                    main_shell (3 tab), home, result, disease_detail,
                              disease_library, history, onboarding
  utils/box_mapping.dart      Đổi toạ độ khung ảnh → widget (BoxFit.cover/contain)
  utils/text_search.dart      Tìm kiếm bỏ dấu tiếng Việt
assets/models/                best_fp32.tflite, labels.txt
```

Model được huấn luyện/xuất trong repo `android_Computer-vision`
(`scripts/export.py`). Thứ tự nhãn trong `labels.txt` phải khớp với model.

## Chạy

```bash
flutter pub get
flutter run            # cần thiết bị Android
flutter test           # unit + widget test
flutter test integration_test/batch_eval_test.dart   # chạy model thật trên thiết bị
flutter build apk --release            # APK universal (ký bằng release key nếu đã cấu hình)
flutter build apk --release --split-per-abi
```

## Phát hành phiên bản mới (CI/CD)

GitHub Actions làm hết phần build và tạo bản phát hành:

- `.github/workflows/ci.yml` — mỗi push vào `main` và mỗi pull request: chạy
  `flutter analyze` + `flutter test`.
- `.github/workflows/release.yml` — khi push tag `v*` (hoặc chạy tay trong tab
  **Actions → Release → Run workflow**): build APK universal + APK theo ABI, kiểm
  tra chữ ký, rồi tạo GitHub Release kèm hướng dẫn cài đặt và `SHA256SUMS.txt`.
  Người khác tải ở trang Releases là cài được ngay.

Cách phát hành:

1. Sửa `version` trong `pubspec.yaml`, tăng **cả build number**, ví dụ
   `version: 1.1.0+2` (Android dùng build number để biết bản nào mới hơn).
2. Commit, push lên `main` và chờ CI xanh.
3. Tạo tag trùng tên phiên bản rồi push tag:

   ```bash
   git tag v1.1.0
   git push origin main --follow-tags
   ```

   Tag phải khớp phần tên trong `pubspec.yaml` (`1.1.0`). Muốn đổi build number
   mà không đổi tên phiên bản thì dùng tag `v1.1.0+3`.

Hoặc vào **Actions → Release → Run workflow** để phát hành theo `version` hiện
có trong `pubspec.yaml`, không cần tạo tag (có thể nhập đè tên/mã phiên bản và
đánh dấu pre-release).

## Ký bản phát hành

APK trên GitHub Releases được ký bằng khóa phát hành riêng (không phải debug key),
nên cài được trên mọi máy và các bản cập nhật cài đè lên nhau được.

- Khóa ký: `android/app/release.jks`; mật khẩu/alias: `android/key.properties`.
  Cả hai đã nằm trong `.gitignore` — **đừng commit**, nhưng hãy **sao lưu ở nơi an
  toàn**. Mất khóa thì không thể phát hành bản cập nhật đè lên bản cũ được nữa
  (người dùng phải gỡ app rồi cài lại).
- CI lấy khóa từ 4 repo secrets: `ANDROID_KEYSTORE_BASE64`
  (nội dung `base64 -w0 android/app/release.jks`), `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. Đổi khóa thì cập nhật lại secrets.
- Máy chưa có `android/key.properties` vẫn build local được, nhưng bản đó ký bằng
  debug key — chỉ dùng để thử, không phát hành.

`android/key.properties` có dạng:

```properties
storePassword=<mật khẩu keystore>
keyPassword=<mật khẩu khóa>
keyAlias=groundnut
storeFile=release.jks
```

Sau này nếu đưa lên Google Play, dùng đúng khóa này (hoặc bật Play App Signing)
và build `flutter build appbundle --release`.

## Nội dung cần duyệt

Toàn bộ nội dung trong `lib/data/disease_info.dart` là bản nháp tham khảo, **chưa
được chuyên gia BVTV duyệt**. Khi duyệt xong, đặt `kContentReviewed = true` và cập
nhật `kContentUpdated` — banner "Nội dung đang chờ chuyên gia duyệt" sẽ tự ẩn.
Thuốc chỉ ghi theo hoạt chất; cần đối chiếu với danh mục thuốc BVTV được phép sử
dụng tại Việt Nam hiện hành.

## Giới hạn đã biết

- "Mức lan" là ước tính từ số vùng và diện tích khung (model không phân đoạn vết
  bệnh), ngưỡng trong `severityFor()` cần hiệu chỉnh với mẫu thực địa.
- Model chưa có lớp "lá khỏe" và "không phải lá lạc" nên ảnh không liên quan vẫn
  có thể cho kết quả; ngưỡng "chưa chắc chắn" giúp giảm nhưng không loại bỏ.
