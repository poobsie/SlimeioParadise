import { Box, Button, LabeledList, ProgressBar, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

export const NanodroneHubConsole = (props) => {
  return (
    <Window width={420} height={520}>
      <Window.Content scrollable>
        <HappinessStatus />
        <StationMetrics />
        <Upgrades />
      </Window.Content>
    </Window>
  );
};

const progressRanges = {
  good: [0.7, Infinity],
  average: [0.4, 0.7],
  bad: [-Infinity, 0.4],
};

const percentOrUnknown = (value) => {
  if (value === null || value === undefined) {
    return '?';
  }
  return `${value}%`;
};

const HappinessStatus = (props) => {
  const { data } = useBackend();
  const {
    global_happiness,
    global_goal,
    carried_happiness,
    max_carry_happiness,
    points_balance,
  } = data;

  const carriedRatio = max_carry_happiness ? carried_happiness / max_carry_happiness : 0;
  const globalRatio = global_goal ? global_happiness / global_goal : 0;

  return (
    <Section title="Happiness">
      <LabeledList>
        <LabeledList.Item label="Collective Happiness">{global_happiness ?? 0}</LabeledList.Item>
        <LabeledList.Item label="Collective Goal">{global_goal ?? '?'}</LabeledList.Item>
        <LabeledList.Item label="Collective Progress">
          <ProgressBar value={globalRatio} ranges={progressRanges} />
        </LabeledList.Item>
        <LabeledList.Item label="Your Carried Happiness">
          <Stack align="center">
            <Stack.Item grow>
              <ProgressBar value={carriedRatio} ranges={progressRanges} />
            </Stack.Item>
            <Stack.Item>
              <Box>
                {carried_happiness ?? 0}/{max_carry_happiness ?? '?'}
              </Box>
            </Stack.Item>
          </Stack>
        </LabeledList.Item>
        <LabeledList.Item label="Your Points">{points_balance ?? 0}</LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const StationMetrics = (props) => {
  const { data } = useBackend();
  const {
    station_integrity,
    station_cleanliness,
    cleanup_progress,
    baseline_integrity,
    baseline_cleanliness,
    baseline_dirty_turfs,
  } = data;

  return (
    <Section title="Station Metrics">
      <LabeledList>
        <LabeledList.Item label={`Integrity (baseline: ${percentOrUnknown(baseline_integrity)})`}>
          <ProgressBar value={(station_integrity ?? 0) / 100} ranges={progressRanges} />
        </LabeledList.Item>
        <LabeledList.Item label={`Cleanliness (baseline: ${percentOrUnknown(baseline_cleanliness)})`}>
          <ProgressBar value={(station_cleanliness ?? 0) / 100} ranges={progressRanges} />
        </LabeledList.Item>
        <LabeledList.Item label={`Cleanup Progress (baseline dirty: ${baseline_dirty_turfs ?? '?'})`}>
          <ProgressBar value={(cleanup_progress ?? 0) / 100} ranges={progressRanges} />
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const Upgrades = (props) => {
  const { act, data } = useBackend();
  const { upgrades = [], points_deposited, points_spent, points_balance } = data;

  return (
    <Section title="Upgrades">
      <LabeledList>
        <LabeledList.Item label="Points Summary">
          <Box>
            Balance: {points_balance ?? 0} (Deposited: {points_deposited ?? 0}, Spent: {points_spent ?? 0})
          </Box>
        </LabeledList.Item>
      </LabeledList>

      {upgrades.map((upgrade) => (
        <Section
          key={upgrade.id}
          title={upgrade.name}
          buttons={
            <Button
              content={upgrade.purchased ? 'Purchased' : `Purchase (${upgrade.cost})`}
              disabled={upgrade.purchased || (points_balance ?? 0) < upgrade.cost}
              onClick={() =>
                act('purchase_upgrade', {
                  id: upgrade.id,
                })
              }
            />
          }
        >
          <Box>{upgrade.desc}</Box>
        </Section>
      ))}
    </Section>
  );
};
