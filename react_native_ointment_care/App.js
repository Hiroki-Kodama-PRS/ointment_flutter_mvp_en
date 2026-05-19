import AsyncStorage from "@react-native-async-storage/async-storage";
import * as ImagePicker from "expo-image-picker";
import * as Notifications from "expo-notifications";
import { StatusBar } from "expo-status-bar";
import { useEffect, useMemo, useState } from "react";
import {
  Alert,
  Image,
  Platform,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View
} from "react-native";

const STORAGE_KEY = "ointment_care_react_native_mvp_v1";
const diagnosisOptions = [
  ["atopicDermatitis", "Atopy"],
  ["acne", "Acne"],
  ["beauty", "Beauty"],
  ["other", "Other"]
];
const productOptions = [
  ["steroidOintment", "Steroid"],
  ["moisturizer", "Moisturizer"],
  ["cosmetic", "Cosmetic"],
  ["other", "Other"]
];
const conditionOptions = [
  ["better", "Better"],
  ["stable", "Stable"],
  ["worse", "Worse"]
];

const initialStore = {
  usageRecords: [],
  skinEntries: [],
  dailyGoalGrams: 2,
  remindersEnabled: false
};

export default function App() {
  const [store, setStore] = useState(initialStore);
  const [isLoading, setIsLoading] = useState(true);
  const [tab, setTab] = useState("home");

  useEffect(() => {
    loadStore();
  }, []);

  const metrics = useMemo(() => buildMetrics(store), [store]);

  async function loadStore() {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      if (raw) {
        setStore({ ...initialStore, ...JSON.parse(raw) });
      }
    } catch {
      showMessage("Could not load saved data.");
    } finally {
      setIsLoading(false);
    }
  }

  async function saveStore(nextStore) {
    setStore(nextStore);
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(nextStore));
  }

  async function addUsage(amountGrams, note) {
    const record = {
      id: makeId("usage"),
      date: todayKey(),
      amountGrams,
      note: note.trim(),
      createdAt: new Date().toISOString()
    };
    const nextStore = {
      ...store,
      usageRecords: [record, ...store.usageRecords]
    };
    await saveStore(nextStore);
    if (nextStore.remindersEnabled) {
      await scheduleNextReminder();
    }
  }

  async function saveSkinEntry(entryInput) {
    const today = todayKey();
    const entry = {
      id: makeId("skin"),
      date: today,
      createdAt: new Date().toISOString(),
      ...entryInput
    };
    const nextStore = {
      ...store,
      skinEntries: [
        entry,
        ...store.skinEntries.filter((item) => item.date !== today)
      ]
    };
    await saveStore(nextStore);
    if (nextStore.remindersEnabled) {
      await scheduleNextReminder();
    }
  }

  async function saveSettings(goalText, remindersEnabled) {
    const goal = Number.parseFloat(goalText);
    if (!Number.isFinite(goal) || goal <= 0) {
      showMessage("Enter the daily target as a number.");
      return;
    }
    const nextStore = { ...store, dailyGoalGrams: goal, remindersEnabled };
    await saveStore(nextStore);
    if (remindersEnabled) {
      await requestNotificationPermissions();
    } else {
      await Notifications.cancelAllScheduledNotificationsAsync();
    }
    showMessage("Settings were saved.");
  }

  async function resetData() {
    await saveStore(initialStore);
    showMessage("Local data was reset.");
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar style="dark" />
      <View style={styles.appHeader}>
        <View>
          <Text style={styles.appTitle}>Ointment Care</Text>
          <Text style={styles.appSubtitle}>iPhone MVP, React Native</Text>
        </View>
        <View style={styles.statusPill}>
          <Text style={styles.statusPillText}>Disconnected</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.screen}>
        {isLoading ? (
          <Text style={styles.emptyText}>Loading...</Text>
        ) : (
          <>
            {tab === "home" && (
              <HomeTab metrics={metrics} store={store} onAddUsage={addUsage} />
            )}
            {tab === "history" && <HistoryTab records={store.usageRecords} />}
            {tab === "skin" && (
              <SkinTab entries={store.skinEntries} onSave={saveSkinEntry} />
            )}
            {tab === "badges" && <BadgesTab metrics={metrics} store={store} />}
            {tab === "settings" && (
              <SettingsTab
                store={store}
                onSave={saveSettings}
                onReset={resetData}
              />
            )}
          </>
        )}
      </ScrollView>

      <View style={styles.navBar}>
        {[
          ["home", "Home"],
          ["history", "History"],
          ["skin", "Skin"],
          ["badges", "Badges"],
          ["settings", "Settings"]
        ].map(([value, label]) => (
          <Pressable
            key={value}
            onPress={() => setTab(value)}
            style={[styles.navItem, tab === value && styles.navItemActive]}
          >
            <Text
              style={[
                styles.navItemText,
                tab === value && styles.navItemTextActive
              ]}
            >
              {label}
            </Text>
          </Pressable>
        ))}
      </View>
    </SafeAreaView>
  );
}

function HomeTab({ metrics, store, onAddUsage }) {
  const [amountText, setAmountText] = useState("");
  const [note, setNote] = useState("");
  const latestSkin = store.skinEntries[0];
  const latestBadge = getLatestBadge(store, metrics);

  async function saveManualUsage() {
    const amount = Number.parseFloat(amountText);
    if (!Number.isFinite(amount) || amount <= 0) {
      showMessage("Enter the ointment amount in grams.");
      return;
    }
    await onAddUsage(amount, note || "Manual entry");
    setAmountText("");
    setNote("");
    showMessage(`Recorded ${amount.toFixed(1)}g.`);
  }

  return (
    <View style={styles.stack}>
      <Card>
        <SectionTitle title="Ointment Usage" />
        <View style={styles.metricGrid}>
          <Metric label="Today" value={`${metrics.todayTotal.toFixed(1)}g`} />
          <Metric label="7 days" value={`${metrics.weekTotal.toFixed(1)}g`} />
          <Metric label="Adherence" value={`${metrics.adherence}%`} />
          <Metric label="Badges" value={`${metrics.earnedBadges}/4`} />
        </View>
      </Card>

      <Card>
        <SectionTitle title="Manual Measurement" />
        <TextInput
          keyboardType="decimal-pad"
          onChangeText={setAmountText}
          placeholder="Amount in grams"
          style={styles.input}
          value={amountText}
        />
        <TextInput
          onChangeText={setNote}
          placeholder="Note"
          style={styles.input}
          value={note}
        />
        <PrimaryButton label="Save Measurement" onPress={saveManualUsage} />
      </Card>

      <View style={styles.twoColumn}>
        <Card style={styles.flexCard}>
          <SectionTitle title="Latest Badge" />
          <Text style={styles.badgeIcon}>{latestBadge.done ? "OK" : "--"}</Text>
          <Text style={styles.cardTitle}>{latestBadge.title}</Text>
          <Text style={styles.bodyText}>{latestBadge.detail}</Text>
        </Card>
        <Card style={styles.flexCard}>
          <SectionTitle title="Skin Journal" />
          {latestSkin?.photoUri ? (
            <Image source={{ uri: latestSkin.photoUri }} style={styles.photo} />
          ) : (
            <View style={styles.photoPlaceholder}>
              <Text style={styles.emptyText}>No photo</Text>
            </View>
          )}
          <Text numberOfLines={2} style={styles.bodyText}>
            {latestSkin
              ? `${labelFor(diagnosisOptions, latestSkin.diagnosis)} / ${labelFor(
                  productOptions,
                  latestSkin.productType
                )}`
              : "No skin photo or note yet."}
          </Text>
        </Card>
      </View>
    </View>
  );
}

function HistoryTab({ records }) {
  return (
    <Card>
      <SectionTitle title="Usage History" />
      {records.length === 0 ? (
        <EmptyState text="No usage records yet." />
      ) : (
        records.map((record) => (
          <ListRow
            key={record.id}
            title={formatDate(record.date)}
            subtitle={record.note || "No note"}
            value={`${record.amountGrams.toFixed(1)}g`}
          />
        ))
      )}
    </Card>
  );
}

function SkinTab({ entries, onSave }) {
  const [diagnosis, setDiagnosis] = useState("atopicDermatitis");
  const [productType, setProductType] = useState("steroidOintment");
  const [productName, setProductName] = useState("");
  const [condition, setCondition] = useState("stable");
  const [itchScore, setItchScore] = useState("3");
  const [rednessScore, setRednessScore] = useState("3");
  const [memo, setMemo] = useState("");
  const [photoUri, setPhotoUri] = useState("");

  async function pickPhoto() {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      showMessage("Photo library permission is needed.");
      return;
    }
    const picked = await ImagePicker.launchImageLibraryAsync({
      allowsEditing: true,
      quality: 0.8
    });
    if (!picked.canceled) {
      setPhotoUri(picked.assets[0].uri);
    }
  }

  async function save() {
    await onSave({
      diagnosis,
      productType,
      productName: productName.trim(),
      condition,
      itchScore: clampScore(itchScore),
      rednessScore: clampScore(rednessScore),
      memo: memo.trim(),
      photoUri
    });
    setProductName("");
    setMemo("");
    setPhotoUri("");
    showMessage("Today's skin status was saved.");
  }

  return (
    <View style={styles.stack}>
      <Card>
        <SectionTitle title="Today's Skin Status" />
        {photoUri ? (
          <Image source={{ uri: photoUri }} style={styles.photoLarge} />
        ) : (
          <View style={styles.photoLargePlaceholder}>
            <Text style={styles.emptyText}>Select a skin photo</Text>
          </View>
        )}
        <SecondaryButton label={photoUri ? "Change Photo" : "Choose Photo"} onPress={pickPhoto} />
        <SegmentedControl
          label="Condition Type"
          options={diagnosisOptions}
          value={diagnosis}
          onChange={setDiagnosis}
        />
        <SegmentedControl
          label="Product Type"
          options={productOptions}
          value={productType}
          onChange={setProductType}
        />
        <TextInput
          onChangeText={setProductName}
          placeholder="Ointment, medicine, or cosmetic name"
          style={styles.input}
          value={productName}
        />
        <SegmentedControl
          label="Status"
          options={conditionOptions}
          value={condition}
          onChange={setCondition}
        />
        <ScoreInput label="Itch" value={itchScore} onChange={setItchScore} />
        <ScoreInput
          label="Redness"
          value={rednessScore}
          onChange={setRednessScore}
        />
        <TextInput
          multiline
          onChangeText={setMemo}
          placeholder="Symptoms, application area, or lifestyle changes"
          style={[styles.input, styles.memoInput]}
          value={memo}
        />
        <PrimaryButton label="Save Skin Status" onPress={save} />
      </Card>

      <Card>
        <SectionTitle title="Recent Skin Logs" />
        {entries.length === 0 ? (
          <EmptyState text="No skin logs yet." />
        ) : (
          entries.map((entry) => (
            <ListRow
              key={entry.id}
              title={`${formatDate(entry.date)} / ${labelFor(
                diagnosisOptions,
                entry.diagnosis
              )}`}
              subtitle={`${labelFor(productOptions, entry.productType)} - ${labelFor(
                conditionOptions,
                entry.condition
              )}\nItch ${entry.itchScore}/10, redness ${entry.rednessScore}/10`}
              value={entry.photoUri ? "Photo" : ""}
            />
          ))
        )}
      </Card>
    </View>
  );
}

function BadgesTab({ metrics, store }) {
  const recordedDays = new Set(store.usageRecords.map((record) => record.date))
    .size;
  const badges = [
    ["First Log", store.usageRecords.length > 0, "First ointment usage recorded"],
    ["3-Day Log", recordedDays >= 3, "Usage recorded on 3 days"],
    ["7-Day Log", recordedDays >= 7, "Usage recorded on 7 days"],
    [
      "Weekly Goal Met",
      metrics.weekTotal >= store.dailyGoalGrams * 7,
      "This week reached the target amount"
    ]
  ];

  return (
    <Card>
      <SectionTitle title="Achievement Badges" />
      {badges.map(([title, done, detail]) => (
        <ListRow
          key={title}
          title={title}
          subtitle={detail}
          value={done ? "Done" : "Locked"}
        />
      ))}
    </Card>
  );
}

function SettingsTab({ store, onSave, onReset }) {
  const [goalText, setGoalText] = useState(store.dailyGoalGrams.toFixed(1));
  const [remindersEnabled, setRemindersEnabled] = useState(
    store.remindersEnabled
  );

  return (
    <View style={styles.stack}>
      <Card>
        <SectionTitle title="Treatment Settings" />
        <TextInput
          keyboardType="decimal-pad"
          onChangeText={setGoalText}
          placeholder="Daily target amount (g)"
          style={styles.input}
          value={goalText}
        />
        <View style={styles.switchRow}>
          <Text style={styles.bodyText}>Enable 24-hour ointment reminders</Text>
          <Switch value={remindersEnabled} onValueChange={setRemindersEnabled} />
        </View>
        <PrimaryButton
          label="Save Settings"
          onPress={() => onSave(goalText, remindersEnabled)}
        />
      </Card>

      <Card>
        <SectionTitle title="Development Notes" />
        <Text style={styles.bodyText}>
          Data is stored locally on this device. Bluetooth LE, clinician
          sharing, cloud sync, and App Store review preparation are planned for
          the next phase.
        </Text>
        <SecondaryButton label="Reset Local Data" onPress={onReset} />
      </Card>
    </View>
  );
}

function Card({ children, style }) {
  return <View style={[styles.card, style]}>{children}</View>;
}

function SectionTitle({ title }) {
  return <Text style={styles.sectionTitle}>{title}</Text>;
}

function Metric({ label, value }) {
  return (
    <View style={styles.metricTile}>
      <Text style={styles.metricValue}>{value}</Text>
      <Text style={styles.metricLabel}>{label}</Text>
    </View>
  );
}

function PrimaryButton({ label, onPress }) {
  return (
    <Pressable onPress={onPress} style={styles.primaryButton}>
      <Text style={styles.primaryButtonText}>{label}</Text>
    </Pressable>
  );
}

function SecondaryButton({ label, onPress }) {
  return (
    <Pressable onPress={onPress} style={styles.secondaryButton}>
      <Text style={styles.secondaryButtonText}>{label}</Text>
    </Pressable>
  );
}

function SegmentedControl({ label, options, value, onChange }) {
  return (
    <View style={styles.segmentBlock}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <View style={styles.segmentWrap}>
        {options.map(([optionValue, optionLabel]) => (
          <Pressable
            key={optionValue}
            onPress={() => onChange(optionValue)}
            style={[
              styles.segment,
              value === optionValue && styles.segmentActive
            ]}
          >
            <Text
              style={[
                styles.segmentText,
                value === optionValue && styles.segmentTextActive
              ]}
            >
              {optionLabel}
            </Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

function ScoreInput({ label, value, onChange }) {
  return (
    <View>
      <Text style={styles.fieldLabel}>{label} 0-10</Text>
      <TextInput
        keyboardType="number-pad"
        maxLength={2}
        onChangeText={onChange}
        style={styles.input}
        value={value}
      />
    </View>
  );
}

function ListRow({ title, subtitle, value }) {
  return (
    <View style={styles.listRow}>
      <View style={styles.listRowText}>
        <Text style={styles.listTitle}>{title}</Text>
        <Text style={styles.listSubtitle}>{subtitle}</Text>
      </View>
      {value ? <Text style={styles.listValue}>{value}</Text> : null}
    </View>
  );
}

function EmptyState({ text }) {
  return (
    <View style={styles.emptyState}>
      <Text style={styles.emptyText}>{text}</Text>
    </View>
  );
}

function buildMetrics(store) {
  const today = todayKey();
  const days = lastNDays(7);
  const todayTotal = store.usageRecords
    .filter((record) => record.date === today)
    .reduce((sum, record) => sum + record.amountGrams, 0);
  const weekTotal = store.usageRecords
    .filter((record) => days.includes(record.date))
    .reduce((sum, record) => sum + record.amountGrams, 0);
  const recordedDays = new Set(store.usageRecords.map((record) => record.date));
  const adherence = Math.round(
    (days.filter((day) => recordedDays.has(day)).length / 7) * 100
  );
  const earnedBadges = [
    store.usageRecords.length > 0,
    recordedDays.size >= 3,
    recordedDays.size >= 7,
    weekTotal >= store.dailyGoalGrams * 7
  ].filter(Boolean).length;

  return { todayTotal, weekTotal, adherence, earnedBadges };
}

function getLatestBadge(store, metrics) {
  const recordedDays = new Set(store.usageRecords.map((record) => record.date))
    .size;
  if (metrics.weekTotal >= store.dailyGoalGrams * 7) {
    return {
      title: "Weekly Goal Met",
      detail: "This week reached the target amount",
      done: true
    };
  }
  if (recordedDays >= 7) {
    return { title: "7-Day Log", detail: "Usage recorded on 7 days", done: true };
  }
  if (recordedDays >= 3) {
    return { title: "3-Day Log", detail: "Usage recorded on 3 days", done: true };
  }
  if (store.usageRecords.length > 0) {
    return {
      title: "First Log",
      detail: "First ointment usage recorded",
      done: true
    };
  }
  return { title: "Locked", detail: "Measure usage to unlock", done: false };
}

async function requestNotificationPermissions() {
  if (Platform.OS === "web") return;
  await Notifications.requestPermissionsAsync();
}

async function scheduleNextReminder() {
  if (Platform.OS === "web") return;
  await requestNotificationPermissions();
  await Notifications.cancelAllScheduledNotificationsAsync();
  await Notifications.scheduleNotificationAsync({
    content: {
      title: "Ointment Care",
      body: "It is time to apply your ointment."
    },
    trigger: { seconds: 24 * 60 * 60 }
  });
}

function showMessage(message) {
  if (Platform.OS === "web") {
    window.alert(message);
    return;
  }
  Alert.alert("Ointment Care", message);
}

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

function lastNDays(count) {
  return Array.from({ length: count }, (_, index) => {
    const date = new Date();
    date.setDate(date.getDate() - (count - 1 - index));
    return date.toISOString().slice(0, 10);
  });
}

function makeId(prefix) {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 100000)}`;
}

function formatDate(dateKey) {
  const date = new Date(`${dateKey}T00:00:00`);
  return date.toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

function labelFor(options, value) {
  return options.find(([optionValue]) => optionValue === value)?.[1] ?? value;
}

function clampScore(value) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) return 0;
  return Math.max(0, Math.min(10, parsed));
}

const colors = {
  blue: "#2563EB",
  green: "#16845B",
  ink: "#172033",
  muted: "#667085",
  line: "#DCE3EA",
  bg: "#F5F7FA",
  pale: "#F1F4F7",
  white: "#FFFFFF"
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: colors.bg
  },
  appHeader: {
    alignItems: "center",
    backgroundColor: colors.white,
    borderBottomColor: colors.line,
    borderBottomWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 16,
    paddingVertical: 12
  },
  appTitle: {
    color: colors.ink,
    fontSize: 22,
    fontWeight: "800"
  },
  appSubtitle: {
    color: colors.muted,
    fontSize: 12
  },
  statusPill: {
    backgroundColor: colors.pale,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6
  },
  statusPillText: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: "700"
  },
  screen: {
    padding: 16,
    paddingBottom: 96
  },
  stack: {
    gap: 12
  },
  card: {
    backgroundColor: colors.white,
    borderColor: colors.line,
    borderRadius: 10,
    borderWidth: 1,
    padding: 16
  },
  sectionTitle: {
    color: colors.ink,
    fontSize: 17,
    fontWeight: "800",
    marginBottom: 12
  },
  metricGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10
  },
  metricTile: {
    backgroundColor: colors.pale,
    borderRadius: 8,
    flexBasis: "47%",
    flexGrow: 1,
    padding: 12
  },
  metricValue: {
    color: colors.ink,
    fontSize: 22,
    fontWeight: "800"
  },
  metricLabel: {
    color: colors.muted,
    fontSize: 13,
    marginTop: 2
  },
  input: {
    backgroundColor: "#FAFBFC",
    borderColor: colors.line,
    borderRadius: 8,
    borderWidth: 1,
    color: colors.ink,
    fontSize: 16,
    marginBottom: 10,
    paddingHorizontal: 12,
    paddingVertical: 12
  },
  memoInput: {
    minHeight: 96,
    textAlignVertical: "top"
  },
  primaryButton: {
    alignItems: "center",
    backgroundColor: colors.blue,
    borderRadius: 8,
    minHeight: 48,
    justifyContent: "center",
    paddingHorizontal: 16
  },
  primaryButtonText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: "800"
  },
  secondaryButton: {
    alignItems: "center",
    borderColor: colors.line,
    borderRadius: 8,
    borderWidth: 1,
    minHeight: 44,
    justifyContent: "center",
    marginBottom: 10,
    paddingHorizontal: 16
  },
  secondaryButtonText: {
    color: colors.ink,
    fontSize: 15,
    fontWeight: "700"
  },
  twoColumn: {
    gap: 12
  },
  flexCard: {
    minHeight: 190
  },
  badgeIcon: {
    color: colors.green,
    fontSize: 30,
    fontWeight: "900",
    textAlign: "center"
  },
  cardTitle: {
    color: colors.ink,
    fontSize: 16,
    fontWeight: "800",
    marginTop: 8,
    textAlign: "center"
  },
  bodyText: {
    color: colors.muted,
    fontSize: 14,
    lineHeight: 20
  },
  photo: {
    borderRadius: 8,
    height: 110,
    marginBottom: 8,
    width: "100%"
  },
  photoPlaceholder: {
    alignItems: "center",
    backgroundColor: "#E8F0FF",
    borderRadius: 8,
    height: 110,
    justifyContent: "center",
    marginBottom: 8
  },
  photoLarge: {
    borderRadius: 8,
    height: 190,
    marginBottom: 10,
    width: "100%"
  },
  photoLargePlaceholder: {
    alignItems: "center",
    backgroundColor: "#E8F0FF",
    borderColor: colors.line,
    borderRadius: 8,
    borderWidth: 1,
    height: 190,
    justifyContent: "center",
    marginBottom: 10
  },
  emptyState: {
    alignItems: "center",
    backgroundColor: colors.pale,
    borderRadius: 8,
    justifyContent: "center",
    minHeight: 96,
    padding: 16
  },
  emptyText: {
    color: colors.muted,
    fontSize: 14
  },
  segmentBlock: {
    marginBottom: 12
  },
  fieldLabel: {
    color: colors.ink,
    fontSize: 14,
    fontWeight: "700",
    marginBottom: 8
  },
  segmentWrap: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8
  },
  segment: {
    borderColor: colors.line,
    borderRadius: 8,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 9
  },
  segmentActive: {
    backgroundColor: colors.blue,
    borderColor: colors.blue
  },
  segmentText: {
    color: colors.ink,
    fontSize: 14,
    fontWeight: "700"
  },
  segmentTextActive: {
    color: colors.white
  },
  listRow: {
    borderTopColor: colors.line,
    borderTopWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 12,
    paddingVertical: 12
  },
  listRowText: {
    flex: 1
  },
  listTitle: {
    color: colors.ink,
    fontSize: 15,
    fontWeight: "800"
  },
  listSubtitle: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 18,
    marginTop: 2
  },
  listValue: {
    color: colors.ink,
    fontSize: 14,
    fontWeight: "800"
  },
  switchRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 14
  },
  navBar: {
    backgroundColor: colors.white,
    borderTopColor: colors.line,
    borderTopWidth: StyleSheet.hairlineWidth,
    bottom: 0,
    flexDirection: "row",
    gap: 4,
    left: 0,
    paddingHorizontal: 8,
    paddingVertical: 10,
    position: "absolute",
    right: 0
  },
  navItem: {
    alignItems: "center",
    borderRadius: 8,
    flex: 1,
    minHeight: 42,
    justifyContent: "center"
  },
  navItemActive: {
    backgroundColor: "#E8F0FF"
  },
  navItemText: {
    color: colors.muted,
    fontSize: 12,
    fontWeight: "700"
  },
  navItemTextActive: {
    color: colors.blue
  }
});
