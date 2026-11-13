Pip KeyPet: веб-симулятор
=========================
site/  — готовий сайт (index.html + pip.wasm + pip.js + three.js локально, без CDN).
Запуск:  cd site && python3 -m http.server 8466   ->  http://localhost:8466
(відкривати файлом з диска не вийде: браузер забороняє завантаження .wasm і модулів з file://)
GitHub Pages: покладіть вміст site/ у docs/sim/ репозиторію й увімкніть Pages.

tools/build-wasi.sh — перезбирає pip.wasm з вашого репозиторію через wasi-sdk (без Emscripten),
якщо ви зміните код у ui/.
Прошивка (C + LVGL) не змінювалась: той самий ui/*.c, що й на брелоку.
