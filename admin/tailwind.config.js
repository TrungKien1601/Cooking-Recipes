const defaultTheme = require("tailwindcss/defaultTheme");
/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  darkMode: "class",
  theme: {
    fontFamily: {
      outfit: ["Outfit", "sans-serif"],
    },
    screens: {
      "2xsm": "375px",
      xsm: "425px",
      "3xl": "2000px",
      ...defaultTheme.screens,
    },
    extend: {
      fontSize: {
        "title-2xl": ["72px", "90px"],
        "title-xl": ["60px", "72px"],
        "title-lg": ["48px", "60px"],
        "title-md": ["36px", "44px"],
        "title-sm": ["30px", "38px"],
        "theme-xl": ["20px", "30px"],
        "theme-sm": ["14px", "20px"],
        "theme-xs": ["12px", "18px"],
      },
      colors: {
        current: "currentColor",
        transparent: "transparent",
        white: "#FFFFFF",
        black: "#101828",
        brand: {
          25: "#F3FDF3",
          50: "#E6F9E6",
          100: "#C9F2C9", 
          200: "#9DE59D",
          300: "#6BD66B",
          400: "#3EC33E",
          500: "#2DA82D",
          600: "#248F24",
          700: "#1D741D",
          800: "#175B17",
          900: "#114411",
          950: "#0A2B0A",
        },
        "green-light": {
          25: "#F2FDF4",
          50: "#EBF9EF",
          100: "#D6F3DD",
          200: "#AEECC0",
          300: "#7CE09A",
          400: "#4AC976",
          500: "#22AD5C",
          600: "#168B48",
          700: "#116F3B",
          800: "#0F5831",
          900: "#0C4829",
          950: "#052916",
        },
        gray: {
          dark: "#19211C", // Dark mode background (thay cho #1A2231)
          25: "#FCFDFD",   // Gần như trắng, ám xíu xanh lá (thay cho #FCFCFD)
          50: "#F6F8F6",   // Nền cực nhạt (thay cho #F9FAFB)
          100: "#EFF1EF",  // Nền nhạt (thay cho #F2F4F7)
          200: "#E0E5E2",  // Viền nhạt (thay cho #E4E7EC)
          300: "#CDD2CE",  // Viền/Icon (thay cho #D0D5DD)
          400: "#99A19C",  // Text phụ (thay cho #98A2B3)
          500: "#666F69",  // Text chính vừa (thay cho #667085)
          600: "#48524B",  // Text chính (thay cho #475467)
          700: "#363E38",  // Tiêu đề (thay cho #344054)
          800: "#222924",  // Tiêu đề đậm (thay cho #1D2939)
          900: "#131915",  // Gần như đen (thay cho #101828)
          950: "#0C100D",  // Đen sâu (thay cho #0C111D)
        },
        orange: {
          25: "#FFFAF5",
          50: "#FFF6ED",
          100: "#FFEAD5",
          200: "#FDDCAB",
          300: "#FEB273",
          400: "#FD853A",
          500: "#FB6514",
          600: "#EC4A0A",
          700: "#C4320A",
          800: "#9C2A10",
          900: "#7E2410",
          950: "#511C10",
        },
        success: {
          25: "#F6FEF9",
          50: "#ECFDF3",
          100: "#D1FADF",
          200: "#A6F4C5",
          300: "#6CE9A6",
          400: "#32D583",
          500: "#12B76A",
          600: "#039855",
          700: "#027A48",
          800: "#05603A",
          900: "#054F31",
          950: "#053321",
        },
        error: {
          25: "#FFFBFA",
          50: "#FEF3F2",
          100: "#FEE4E2",
          200: "#FECDCA",
          300: "#FDA29B",
          400: "#F97066",
          500: "#F04438",
          600: "#D92D20",
          700: "#B42318",
          800: "#912018",
          900: "#7A271A",
          950: "#55160C",
        },
        warning: {
          25: "#FFFCF5",
          50: "#FFFAEB",
          100: "#FEF0C7",
          200: "#FEDF89",
          300: "#FEC84B",
          400: "#FDB022",
          500: "#F79009",
          600: "#DC6803",
          700: "#B54708",
          800: "#93370D",
          900: "#7A2E0E",
          950: "#4E1D09",
        },
        "theme-pink": {
          500: "#EE46BC",
        },
        "theme-purple": {
          500: "#7A5AF8",
        },
      },
      boxShadow: {
        "theme-md":
          "0px 4px 8px -2px rgba(16, 24, 40, 0.10), 0px 2px 4px -2px rgba(16, 24, 40, 0.06)",
        "theme-lg":
          "0px 12px 16px -4px rgba(16, 24, 40, 0.08), 0px 4px 6px -2px rgba(16, 24, 40, 0.03)",

        "theme-sm":
          "0px 1px 3px 0px rgba(16, 24, 40, 0.10), 0px 1px 2px 0px rgba(16, 24, 40, 0.06)",
        "theme-xs": "0px 1px 2px 0px rgba(16, 24, 40, 0.05)",
        "theme-xl":
          "0px 20px 24px -4px rgba(16, 24, 40, 0.08), 0px 8px 8px -4px rgba(16, 24, 40, 0.03)",
        datepicker: "-5px 0 0 #262d3c, 5px 0 0 #262d3c",
        "focus-ring": "0px 0px 0px 4px rgba(70, 95, 255, 0.12)",
        "slider-navigation":
          "0px 1px 2px 0px rgba(16, 24, 40, 0.10), 0px 1px 3px 0px rgba(16, 24, 40, 0.10)",
        tooltip:
          "0px 4px 6px -2px rgba(16, 24, 40, 0.05), -8px 0px 20px 8px rgba(16, 24, 40, 0.05)",
      },
      dropShadow: {
        "4xl": [
          "0 35px 35px rgba(0, 0, 0, 0.25)",
          "0 45px 65px rgba(0, 0, 0, 0.15)",
        ],
      },
      zIndex: {
        999999: "999999",
        99999: "99999",
        9999: "9999",
        999: "999",
        99: "99",
        9: "9",
        1: "1",
      },
      spacing: {
        4.5: "1.125rem",
        5.5: "1.375rem",
        6.5: "1.625rem",
        7.5: "1.875rem",
        8.5: "2.125rem",
        9.5: "2.375rem",
        10.5: "2.625rem",
        11.5: "2.875rem",
        12.5: "3.125rem",
        13: "3.25rem",
        13.5: "3.375rem",
        14.5: "3.625rem",
        15: "3.75rem",
      },
    },
  },
  plugins: [require("@tailwindcss/forms"), require("autoprefixer")],
};
