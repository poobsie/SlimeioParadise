/**
 * Job Preferences tab for character creator
 * Allows setting job priorities (Never/Low/Medium/High), alternate titles, and occupation behavior
 * Features:
 * - Three-column layout organized by department
 * - Left click to raise priority, right click to lower
 * - High priority override (only one job can be high)
 * - Assistant toggle
 * - Alternate job title selection via dropdown
 * - Cycle behavior for unavailable preferences
 */

import { Box, Button, Dropdown, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';

type JobData = {
  title: string;
  flag: number;
  selection_color: string;
  alt_titles?: string[];
  current_priority: number; // 0 = never, 1 = low, 2 = medium, 3 = high
  selected_alt_title?: string;
  unavailable?: boolean;
  unavailable_reason?: string;
};

type DepartmentData = {
  name: string;
  color: string;
  accent_color: string;
  jobs: JobData[];
  column: number; // 1, 2, or 3
};

type JobPreferencesData = {
  job_preferences?: {
    departments?: DepartmentData[];
    alternate_option?: number; // 0 = random, 1 = assistant, 2 = return to lobby
    assistant_enabled?: boolean;
  };
};

const PRIORITY_LEVELS = ['Never', 'Low', 'Medium', 'High'];
const PRIORITY_COLORS = ['#8b0000', '#ffa500', '#228b22', '#4169e1']; // Dark red, orange, forest green, royal blue

const ALTERNATE_OPTIONS = [
  { value: 0, label: 'Get random job if preferences unavailable' },
  { value: 1, label: 'Be an assistant if preferences unavailable' },
  { value: 2, label: 'Return to lobby if preferences unavailable' },
];

export const JobPreferencesTab = (props) => {
  const { act, data } = useBackend<JobPreferencesData>();
  
  const jobPrefs = data.job_preferences || {};
  const departments = jobPrefs.departments || [];
  const alternate_option = jobPrefs.alternate_option || 0;
  const assistant_enabled = jobPrefs.assistant_enabled || false;

  // Organize departments by column (1, 2, 3)
  const column1 = departments.filter((d) => d.column === 1);
  const column2 = departments.filter((d) => d.column === 2);
  const column3 = departments.filter((d) => d.column === 3);

  const handleJobClick = (job: JobData, isRightClick: boolean) => {
    if (job.unavailable || (assistant_enabled && job.title !== 'Assistant')) {
      return;
    }

    let newPriority = job.current_priority;

    if (isRightClick) {
      // Right click: lower priority
      newPriority = Math.max(0, job.current_priority - 1);
    } else {
      // Left click: raise priority (will handle high override on backend)
      newPriority = Math.min(3, job.current_priority + 1);
    }

    act('job_preferences_action', {
      job_action: 'set_job_priority',
      job_title: job.title,
      priority: newPriority,
    });
  };

  const handleAltTitleChange = (job: JobData, newTitle: string) => {
    act('job_preferences_action', {
      job_action: 'set_alt_title',
      job_title: job.title,
      alt_title: newTitle,
    });
  };

  const toggleAssistant = () => {
    act('job_preferences_action', {
      job_action: 'toggle_assistant',
      enabled: !assistant_enabled,
    });
  };

  const handleAlternateOptionChange = (value: number) => {
    act('job_preferences_action', {
      job_action: 'set_alternate_option',
      option: value,
    });
  };

  const renderDepartment = (department: DepartmentData) => {
    return (
      <Section
        key={department.name}
        title={department.name}
        style={{
          backgroundColor: department.color,
          border: `2px solid ${department.accent_color}`,
          marginBottom: '0.5em',
        }}
      >
        <Stack vertical>
          {department.jobs.map((job) => {
            const isDisabled = job.unavailable || (assistant_enabled && job.title !== 'Assistant');
            const displayTitle = job.selected_alt_title || job.title;

            return (
              <Stack.Item key={job.title}>
                <Stack fill>
                  {/* Job Title/Alternate Title Selector */}
                  <Stack.Item grow>
                    {job.alt_titles && job.alt_titles.length > 0 ? (
                      <Dropdown
                        width="100%"
                        selected={displayTitle}
                        disabled={isDisabled}
                        options={[job.title, ...job.alt_titles]}
                        onSelected={(value) => handleAltTitleChange(job, value)}
                      />
                    ) : (
                      <Box
                        bold
                        color={isDisabled ? 'grey' : 'white'}
                        style={{
                          textDecoration: isDisabled ? 'line-through' : 'none',
                          padding: '0.33em',
                        }}
                      >
                        {job.title}
                        {job.unavailable_reason && (
                          <Box as="span" color="bad" ml={1}>
                            [{job.unavailable_reason}]
                          </Box>
                        )}
                      </Box>
                    )}
                  </Stack.Item>

                  {/* Priority Buttons */}
                  {!job.unavailable && (
                    <Stack.Item>
                      <Button
                        fluid
                        disabled={isDisabled}
                        color={isDisabled ? 'grey' : undefined}
                        style={{
                          backgroundColor: isDisabled ? undefined : PRIORITY_COLORS[job.current_priority],
                          minWidth: '90px',
                          fontWeight: 'bold',
                        }}
                        onClick={(e) => handleJobClick(job, false)}
                        onContextMenu={(e) => {
                          e.preventDefault();
                          handleJobClick(job, true);
                        }}
                        tooltip={
                          isDisabled
                            ? 'Disabled while Assistant is enabled'
                            : 'Left click to raise priority, right click to lower. Only one job can be High priority.'
                        }
                      >
                        {PRIORITY_LEVELS[job.current_priority]}
                      </Button>
                    </Stack.Item>
                  )}
                </Stack>
              </Stack.Item>
            );
          })}
        </Stack>
      </Section>
    );
  };

  return (
    <Section fill scrollable>
      <Stack vertical>
        {/* Assistant Toggle */}
        <Stack.Item>
          <Section
            title="Assistant"
            style={{
              backgroundColor: '#d6d6d6',
              marginBottom: '0.5em',
            }}
            buttons={
              <Button
                icon={assistant_enabled ? 'toggle-on' : 'toggle-off'}
                selected={assistant_enabled}
                onClick={toggleAssistant}
                tooltip={
                  assistant_enabled
                    ? 'You will only spawn as Assistant'
                    : 'You can spawn as other jobs based on your preferences'
                }
              >
                {assistant_enabled ? 'Yes' : 'No'}
              </Button>
            }
          >
            <Box color="label">
              {assistant_enabled
                ? 'You will only be eligible for the Assistant role. All other job preferences are disabled.'
                : 'Toggle this to only spawn as Assistant, ignoring all other job preferences.'}
            </Box>
          </Section>
        </Stack.Item>

        {/* Cycle Behavior */}
        <Stack.Item>
          <Section
            title="Job Assignment Behavior"
            style={{
              marginBottom: '0.5em',
            }}
          >
            <LabeledList>
              <LabeledList.Item label="If preferences unavailable">
                <Dropdown
                  width="100%"
                  selected={ALTERNATE_OPTIONS.find((opt) => opt.value === alternate_option)?.label || ALTERNATE_OPTIONS[0].label}
                  options={ALTERNATE_OPTIONS.map((opt) => opt.label)}
                  onSelected={(selected) => {
                    const option = ALTERNATE_OPTIONS.find((opt) => opt.label === selected);
                    if (option) {
                      handleAlternateOptionChange(option.value);
                    }
                  }}
                />
              </LabeledList.Item>
            </LabeledList>
          </Section>
        </Stack.Item>

        {/* Three-Column Job Layout */}
        <Stack.Item>
          <Stack fill>
            {/* Column 1: Assistant, Engineering, Medical, Science */}
            <Stack.Item basis="33.33%">
              <Stack vertical fill>
                {column1.map((dept) => (
                  <Stack.Item key={dept.name}>
                    {renderDepartment(dept)}
                  </Stack.Item>
                ))}
              </Stack>
            </Stack.Item>

            {/* Column 2: Security, Synthetics, Command */}
            <Stack.Item basis="33.33%">
              <Stack vertical fill>
                {column2.map((dept) => (
                  <Stack.Item key={dept.name}>
                    {renderDepartment(dept)}
                  </Stack.Item>
                ))}
              </Stack>
            </Stack.Item>

            {/* Column 3: Supply, Service */}
            <Stack.Item basis="33.33%">
              <Stack vertical fill>
                {column3.map((dept) => (
                  <Stack.Item key={dept.name}>
                    {renderDepartment(dept)}
                  </Stack.Item>
                ))}
              </Stack>
            </Stack.Item>
          </Stack>
        </Stack.Item>

        {/* Help Text */}
        <Stack.Item>
          <Section
            title="Instructions"
            style={{
              marginTop: '0.5em',
            }}
          >
            <Stack vertical>
              <Stack.Item>
                <Box bold mb={0.5}>Priority Levels:</Box>
                <Box as="ul" ml={2}>
                  <li>
                    <Box as="span" style={{ color: PRIORITY_COLORS[3], fontWeight: 'bold' }}>
                      High
                    </Box>
                    : Top priority - you want this job (only one job can be High)
                  </li>
                  <li>
                    <Box as="span" style={{ color: PRIORITY_COLORS[2], fontWeight: 'bold' }}>
                      Medium
                    </Box>
                    : Willing to take this job
                  </li>
                  <li>
                    <Box as="span" style={{ color: PRIORITY_COLORS[1], fontWeight: 'bold' }}>
                      Low
                    </Box>
                    : Will accept if nothing else available
                  </li>
                  <li>
                    <Box as="span" style={{ color: PRIORITY_COLORS[0], fontWeight: 'bold' }}>
                      Never
                    </Box>
                    : Do not assign this job
                  </li>
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Box bold mb={0.5}>Controls:</Box>
                <Box as="ul" ml={2}>
                  <li>Left click a job priority to increase it</li>
                  <li>Right click a job priority to decrease it</li>
                  <li>Setting a new job to High will automatically demote your current High job to Medium</li>
                  <li>Use the dropdown on a job to select an alternate title (e.g., "Medical Doctor" → "Surgeon")</li>
                  <li>Toggle Assistant to only spawn as Assistant, disabling all other job preferences</li>
                </Box>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};
