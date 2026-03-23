import { AcrylicOrangeTheme } from '@wso2/oxygen-ui';

// Extend the OxygenUI theme with custom tokens
export const customTheme = {
  ...AcrylicOrangeTheme,
  palette: {
    ...AcrylicOrangeTheme.palette,
    text: {
      ...AcrylicOrangeTheme.palette.text,
      tertiary: AcrylicOrangeTheme.palette.mode === 'light' ? '#00000099' : '#FFFFFF99',
    },
  },
};
