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

## Phát hành tự động (CI/CD)

- `.github/workflows/ci.yml` — mỗi push vào `main` và mỗi pull request: chạy
  `flutter analyze` + `flutter test`.
- `.github/workflows/release.yml` — **mỗi push vào `main` tự động phát hành**:
  1. chạy `flutter analyze` + `flutter test`;
  2. tự tăng phiên bản (mặc định patch: `1.0.0` → `1.0.1`) và build number;
  3. commit `chore(release): v1.0.1+2` + tạo tag `v1.0.1`;
  4. build APK universal + APK theo ABI, kiểm tra chữ ký, tạo GitHub Release kèm
     hướng dẫn cài đặt và `SHA256SUMS.txt`.

Không cần làm gì thêm: sửa code → commit → push `main` → khoảng 5 phút sau bản
mới có trên trang Releases.

Điều khiển bằng commit message:

| Ghi trong commit message | Tác dụng |
| --- | --- |
| `[release:minor]` | tăng minor: `1.2.3` → `1.3.0` |
| `[release:major]` | tăng major: `1.2.3` → `2.0.0` |
| `[skip release]` | chỉ push code, không build/phát hành (vd. sửa README) |

Muốn nhảy thẳng tới một phiên bản cụ thể thì sửa `version` trong `pubspec.yaml`
lên cao hơn bản gần nhất (workflow tôn trọng version đó, chỉ đảm bảo build number
tăng). Sau khi workflow tự commit phiên bản mới vào `main`, ở máy nhớ
`git pull --rebase` trước khi push tiếp để tránh lệch nhánh.

Cần phát hành lại mà không tăng phiên bản: **Actions → Release → Run workflow**.
Vẫn có thể push tag thủ công (`git tag v1.2.3 && git push origin v1.2.3`) — tag
phải khớp `version` trong `pubspec.yaml`.

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
