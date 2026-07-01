# entry/src/main/ets/storage/PreferencesLocalStorageAdapter.ets

```typescript
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { LocalStorageAdapter } from './LocalStorageContract';

export class PreferencesLocalStorageAdapter implements LocalStorageAdapter {
  private readonly context: common.UIAbilityContext;
  private readonly storeName: string = 'eat_what_preferences';

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async getString(key: string, defaultValue: string): Promise<string> {
    try {
      const store: preferences.Preferences = await preferences.getPreferences(this.context, this.storeName);
      return await store.get(key, defaultValue) as string;
    } catch (error) {
      return defaultValue;
    }
  }

  async putString(key: string, value: string): Promise<void> {
    try {
      const store: preferences.Preferences = await preferences.getPreferences(this.context, this.storeName);
      await store.put(key, value);
      await store.flush();
    } catch (error) {
      throw new Error('本地保存失败');
    }
  }
}

```
