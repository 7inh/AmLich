# Third-party notices

Âm Lịch is a fork of [ZzzM/CalendarX](https://github.com/ZzzM/CalendarX),
Copyright © 2020–2025 ZzzM, licensed under AGPL-3.0. The original LICENSE is retained.

The new-moon calculations in VietnameseLunarCalendar.swift adapt the new/full
phase corrections in [astronomia](https://github.com/commenthol/astronomia/blob/master/src/moonphase.js),
which implements chapter 49 of Jean Meeus, Astronomical Algorithms.
The Vietnamese month assignment follows the astronomical rules of the Vietnamese
lunisolar calendar, evaluated at UTC+7. No Chinese holiday or compensatory workday
schedule is used by the fork.

## astronomia

The MIT License (MIT)

Copyright (c) 2013 Sonia Keys
Copyright (c) 2016 Commenthol

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Dependencies inherited from CalendarX

- Sparkle: MIT — https://github.com/sparkle-project/Sparkle
- Schedule: MIT — https://github.com/luoxiu/Schedule
- Swift Algorithms: Apache-2.0 — https://github.com/apple/swift-algorithms
- Swift Numerics: Apache-2.0 — https://github.com/apple/swift-numerics

These dependencies retain their own license notices in their source packages.

## Vietnamese daily quote compilation

The bundled `daily_quotes.json` is a filtered, deduplicated subset of 1,000
entries from [trananhtung/danh-ngon](https://github.com/trananhtung/danh-ngon),
revision `d41ef22a98435fd3cbd75298463872d038c658e4`. The upstream compilation
is published under MIT; the full notice follows. Individual quotations,
translations and attributions originate from the upstream collection and
are not independently verified. No claim is made to relicense original works.
Each entry retains its source link; the resource records the upstream SHA256.
Reproduce the import with `python3 scripts/import-quotes.py`.

MIT License

Copyright (c) 2026 danh-ngon contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
