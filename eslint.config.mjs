import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  globalIgnores([
    "dist/**",
    ".vinext/**",
    ".wrangler/**",
    ".sites-runtime/**",
    "outputs/**",
    "work/**",
    "public/assets/runtime/**",
    "public/assets/startup/**",
    "public/leaflet.js",
    "public/leaflet-maplibre.js",
    "public/maplibre.js",
    "public/qrcode.js",
    "vendor/**",
    "mobile/www/**",
    "mobile/android/**",
    "mobile/ios/**",
  ]),
  {
    files: ["**/*.cjs", "public/core.js", "public/traffic-motion.js"],
    rules: {
      // CommonJS is required by these existing Node/UMD modules.
      "@typescript-eslint/no-require-imports": "off",
    },
  },
  {
    files: ["components/ui/**/*.{ts,tsx}", "hooks/use-mobile.ts"],
    rules: {
      // These files are vendored verbatim from shadcn@4.17.0. Keep the
      // registry source intact while applying the stricter rules to Site code.
      "@typescript-eslint/no-unused-vars": "off",
      "react-hooks/purity": "off",
      "react-hooks/set-state-in-effect": "off",
    },
  },
]);

export default eslintConfig;
