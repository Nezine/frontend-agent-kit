import { Link } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import type { ComponentProps } from 'react';
import { Platform } from 'react-native';

// NOTE (build fix, 2026-11-13): the tabs template types href as `string`,
// which fails once expo-router's typed routes are generated (a plain string
// is not assignable to the Href union). Accept Link's own href type instead;
// behaviour unchanged (external URLs are strings at runtime, as before).
export function ExternalLink(
  props: Omit<ComponentProps<typeof Link>, 'href'> & {
    href: ComponentProps<typeof Link>['href'];
  },
) {
  return (
    <Link
      target="_blank"
      {...props}
      href={props.href}
      onPress={(e) => {
        if (Platform.OS !== 'web') {
          // Prevent the default behavior of linking to the default browser on native.
          e.preventDefault();
          // Open the link in an in-app browser.
          WebBrowser.openBrowserAsync(props.href as string);
        }
      }}
    />
  );
}
