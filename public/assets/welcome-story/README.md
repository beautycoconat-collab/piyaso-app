# Welcome story assets

The fixed road background and music were supplied by the site owner. The music was extracted from `gemini_generated_video_E7003C5E.mp4` as a 96 kbps MP3, with a short fade at each end for looping. Audio is not part of the image-ready gate and attempts to start automatically; browsers that reject autoplay retry on the first ordinary interaction, unless the visitor has muted sound.

Final project assets:
- `public/assets/welcome-story/coastal-road-v1.webp`
- `public/assets/welcome-story/black-car-v1.webp`
- `public/assets/welcome-story/white-car-v1.webp`
- `public/assets/welcome-story/smile-v1.webp`
- `public/assets/welcome-story/boy-smile-v1.webp`
- `public/assets/welcome-story/tulip-v1.webp`
- `public/assets/welcome-story/music-v1.mp3`

The four cutouts were prepared with the built-in Imagegen tool and encoded as WebP with alpha. The original supplied direction, perspective, colors and subject were preserved. No composite video is downloaded for the story.

Prompt used for each cutout (subject substituted below):

> Use case: background-extraction. Edit target: the provided image. Produce an exact clean transparent-background cutout of [subject]. Remove only the exterior white background. Keep the original subject, colors, lighting, details, exact perspective, orientation, and full silhouette unchanged. For the badge preserve the interior blue/pink disc background and the complete neon border and pointed tail. For the car preserve all opaque white and light paint, glass and metallic highlights. No white rectangle, no new background, no added objects, no text, no rotation, no cropped parts. Output one isolated subject with true alpha transparency.

Subjects:
- the entire black sedan, rear three-quarter view pointing upper right
- the entire white sedan, front three-quarter view pointing lower left
- the whole pink neon location-pin badge containing the smiling illustrated girl
- the whole cyan neon location-pin badge containing the pink tulip

The horn, tulip pop and smile chimes use Web Audio oscillators. The visual timeline uses Web Animations transforms and opacity; it pauses in hidden tabs. Reduced-motion mode shows the final composition without travel. Music continues between the intro screens and stops on leaving the introduction.

The supplied smiling male badge is revealed on the black car at 5.55 seconds, after the girl's reveal at 4.8 seconds, and follows that car when it leaves. Its exterior white background was removed with built-in Imagegen, preserving the original face, gentle smile, hairstyle, clothes, complete blue/purple interior disc, cyan neon circular border and pointed tail.

Autoplay diagnostics on the hidden audio element record `data-playback="blocked"` and `data-playback-error="NotAllowedError"` when the browser refuses playback. This is a browser/host permission decision. It cannot be overridden by page JavaScript. For a separately owned native WKWebView wrapper, its native configuration controls `mediaTypesRequiringUserActionForPlayback`; the hosted site cannot set the embedding application's configuration.
