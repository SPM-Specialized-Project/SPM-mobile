# Mobile CI/CD

The workflow in `.github/workflows/mobile-ci.yml` has two parts:

- Pull requests and pushes run Flutter analysis/tests and backend tests on GitHub-hosted Ubuntu runners.
- Pushes and manual runs build split-per-ABI release APKs on a Windows self-hosted runner, after both quality jobs pass. The APKs are uploaded as a GitHub Actions artifact for 14 days.

The APK artifact is for internal review and installation. The Android build number follows the GitHub Actions run number so subsequent builds can update an installed internal build. This workflow does not sign with a production key, publish a release, or upload to Google Play.

## Enable the Windows build runner

At setup time, `SPM-mobile` has no registered self-hosted runners. `SPM-frontend` has a Windows runner with the `local-deploy` label, but its current registration is not available to this repository automatically.

Use one of these options:

1. If the Windows runner is managed by an organization runner group, allow that group to access `SPM-mobile` and make sure its runner has the labels `self-hosted`, `windows`, `x64`, and `local-deploy`.
2. Otherwise, register a separate runner for `SPM-mobile` on the same Windows host. In `SPM-mobile` → **Settings** → **Actions** → **Runners**, choose **New self-hosted runner**, select Windows x64, and follow GitHub's displayed setup commands. Extract it to a separate directory from the `SPM-frontend` runner and add the `local-deploy` label during configuration. Register it as a Windows service so it is available when no user is signed in.

Do not copy a runner registration token into this repository; GitHub displays a temporary token during runner setup. Keep the mobile runner current and restrict repository write access because self-hosted runners execute repository code.

## Prepare the Windows host

The workflow installs Flutter 3.47.7 with `subosito/flutter-action`. The host still needs a working Android toolchain: JDK, Android SDK, and accepted Android SDK licenses. Before relying on the runner, verify `flutter doctor -v` and `flutter doctor --android-licenses` on that host.

## Configure the backend URL

Optionally set the repository Actions variable `SPM_API_BASE_URL` under **Settings** → **Secrets and variables** → **Actions** → **Variables**. Set it to the API host root, for example `https://example.invalid`, without `/api`; app request paths already include `/api`. The variable is not a secret. If it is unset, the app's `AppConfig` default is used.

## Get an APK

After the self-hosted runner is available, push a branch or start **Mobile CI/CD** from the Actions tab with **Run workflow**. When the `package-android` job succeeds, open that workflow run and download `spm-mobile-apks-<run>-<attempt>-<commit>`. The archive contains the ABI-specific APKs under `arm64-v8a`, `armeabi-v7a`, and `x86_64`.

Pull requests intentionally do not run on the self-hosted runner; they run the quality checks on GitHub-hosted runners only.
