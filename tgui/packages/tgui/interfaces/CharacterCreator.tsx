/**
 * Main frontend interface for character creator
 * Backend sibling: code/modules/client/preference/character_creator_tgui.dm
 */

import { useEffect, useState } from 'react';
import * as React from 'react';
import {
  Box,
  Button,
  ColorBox,
  Divider,
  Dropdown,
  Icon,
  ImageButton,
  Input,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import { createSearch } from 'tgui-core/string';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { BasicInformation } from './CharacterCreator/basic_information';
import { CharacterPreview } from './CharacterCreator/character_preview';
import { CharacterSelection } from './CharacterCreator/character_selection';
import { SpeciesSelection } from './CharacterCreator/species_selection';

interface CharacterCreatorData {
  available_prosthetics?: { [key: string]: any[] };
  prosthetic_states?: { [key: string]: string };
  is_machine_species?: boolean;
  selected_quirks?: string[];
  quirk_balance?: number;
  all_quirks?: Quirk[];
  // Loadout data
  gear_slots?: number;
  max_gear_slots?: number;
  selected_gears?: string[];
  gears?: Record<string, Record<string, Gear>>;
  user_tier?: number;
  // Species data
  species_info?: Record<string, SpeciesInfo>;
  [key: string]: any;
}

type CharacterData = {
  real_name: string;
  age: number;
  species: string;
  species_has_hair?: boolean;
  species_has_facial_hair?: boolean;
  species_has_wings?: boolean;
  gender: string;
  body_type: string;
  // Physical characteristics
  physique?: string;
  height?: string;
  runechat_color?: string;
  // Background settings
  language?: string;
  b_type?: string;
  disabilities?: number;
  nanotrasen_relation?: string;
  cyborg_brain_type?: string;
  // AI Settings
  ai_name?: string;
  ai_core_display?: string;
  ai_hologram?: string;
  ai_hologram_color?: string;
  // Cyborg Settings  
  cyborg_name?: string;
  // Character records
  med_record?: string;
  sec_record?: string;
  gen_record?: string;
  // Hair
  h_style: string;
  h_colour: string;
  h_sec_colour: string;
  h_gradient_style: string;
  h_gradient_colour: string;
  f_style: string;
  f_colour: string;
  f_sec_colour: string;
  // Wings
  wing_style?: string;
  // Eyes
  e_colour: string;
  // Skin
  s_colour: string;
  s_tone: number;
  // Clothing
  underwear: string;
  undershirt: string;
  socks: string;
  backbag: string;
  // Other
  flavor_text: string;
  // Preview
  has_preview: boolean;
  preview_timestamp: number;
  // Available options
  available_species: string[];
  available_physiques?: string[];
  available_heights?: string[];
  available_languages?: string[];
  available_blood_types?: string[];
  available_disabilities?: Record<string, DisabilityInfo>;
  available_accents?: Record<string, DisabilityInfo>;
  available_nanotrasen_relations?: string[];
  available_cyborg_brain_types?: string[];
  // AI/Cyborg options
  available_ai_core_displays?: string[];
  available_ai_holograms?: string[];
  available_hair_styles: HairStyle[];
  available_facial_hair_styles: HairStyle[];
  available_hair_gradients: HairStyle[];
  available_wings?: HairStyle[];
  available_underwear: HairStyle[];
  available_undershirt: HairStyle[];
  available_socks: HairStyle[];
  available_backpack_types: BackpackType[];
  available_genders: string[];
  // Character selection
  character_saves: CharacterSave[];
  active_slot: number;
  // Component data
  basic_information?: {
    real_name: string;
    age: number;
    gender: string;
    available_genders: string[];
  };
  species_selection?: {
    selected_species: string;
    available_species: Record<
      string,
      {
        name: string;
        description: string;
        flesh_color: string;
        icon: string;
      }
    >;
  };
  // Antag preferences
  antag_preferences?: Record<string, boolean>;
  available_antags?: AntagInfo[];
};

type HairStyle = {
  name: string;
  icon: string;
  icon_state: string;
};

type BackpackType = {
  name: string;
  value: string;
};

type Quirk = {
  name: string;
  cost: number;
  desc: string;
  path: string;
};

type Gear = {
  name: string;
  desc: string;
  icon: string;
  icon_state: string;
  cost: number;
  gear_tier: number;
  allowed_roles: string[];
  tweaks: Record<string, Tweak[]>;
};

type Tweak = {
  name: string;
  icon: string;
  tooltip: string;
};

type SpeciesInfo = {
  name: string;
  description: string;
};

type CharacterSave = {
  slot: number;
  name: string;
  species: string;
  is_active: boolean;
  valid_save: boolean;
  preview_headshot: string;
};

type DisabilityInfo = {
  name: string;
  flag: number;
};

type DisabilityListItem = {
  key: string;
  name: string;
  flag: number;
  selected: boolean;
};

type AntagInfo = {
  name: string;
  key: string;
  description: string;
  icon?: string;
};

enum Tab {
  Appearance = 0,
  Background = 1,
  Loadout = 2,
  Quirks = 3,
  JobPreferences = 4,
  AntagPreferences = 5,
}

enum AppearanceTab {
  General = 0,
  Species = 1,
  Hair = 2,
  FacialHair = 3,
  Wings = 4,
  Clothing = 5,
  Prosthetics = 6,
}

enum ClothingCategory {
  Underwear = 0,
  Undershirt = 1,
  Socks = 2,
  Backpack = 3,
}

enum ProstheticsCategory {
  Head = 0,
  LeftArm = 1,
  RightArm = 2,
  LeftHand = 3,
  RightHand = 4,
  LeftLeg = 5,
  RightLeg = 6,
  LeftFoot = 7,
  RightFoot = 8,
  Chest = 9,
}

// Character selector component for switching between character slots
const CharacterSelector = (props) => {
  const { data } = useBackend<CharacterData>();
  const { character_saves } = data;

  return (
    <Stack.Item>
      <div
        style={{
          borderBottom: '1px solid #666',
          marginBottom: '8px',
        }}
      >
        <CharacterSelection character_saves={character_saves} />
      </div>
    </Stack.Item>
  );
};

// Main character creator component
export const CharacterCreator = (props) => {
  const { act, data } = useBackend<CharacterData>();

  return (
    <Window width={990} height={910} title="Character Creator (New)">
      <Window.Content>
        <Stack fill vertical>
          <CharacterSelector />
          <Stack.Item grow style={{ paddingBottom: '80px', overflowY: 'auto' }}>
            <AppearanceTabComponent />
          </Stack.Item>
        </Stack>
        {/* Fixed bottom panel */}
        <div
          style={{
            position: 'fixed',
            bottom: '20px',
            left: '20px',
            right: '20px',
            zIndex: 1000,
            backgroundColor: 'rgba(32, 32, 32, 0.95)',
            border: '1px solid #666',
            borderRadius: '4px',
            padding: '8px',
          }}
        >
          <CharacterActions />
        </div>
      </Window.Content>
    </Window>
  );
};

const AppearanceTabComponent = (props) => {
  const { act, data } = useBackend<CharacterData>();
  const {
    real_name,
    age,
    species,
    species_has_hair = true,
    species_has_facial_hair = true,
    species_has_wings = false,
    gender,
    body_type,
    physique,
    height,
    runechat_color,
    flavor_text,
    available_species,
    available_physiques,
    available_heights,
    available_genders,
    // Basic information data
    basic_information,
    species_selection,
    available_hair_styles,
    available_facial_hair_styles,
    available_hair_gradients,
    available_wings,
    available_underwear,
    available_undershirt,
    available_socks,
    available_backpack_types,
    h_style,
    h_colour,
    h_sec_colour,
    h_gradient_style,
    h_gradient_colour,
    f_style,
    f_colour,
    f_sec_colour,
    wing_style,
    e_colour,
    s_colour,
    underwear,
    undershirt,
    socks,
    backbag,
    has_preview,
    preview_timestamp,
  } = data;

  const [selectedMainTab, setSelectedMainTab] = useState<Tab>(Tab.Appearance);
  const [selectedAppearanceTab, setSelectedAppearanceTab] = useState<AppearanceTab>(AppearanceTab.General);
  const [previousSpecies, setPreviousSpecies] = useState<string>('');

  // When we change species we might need to back out to General if the current tab is now invalid
  React.useEffect(() => {
    if (previousSpecies !== '' && previousSpecies !== species) {
      const isCurrentTabValid =
        selectedAppearanceTab === AppearanceTab.General ||
        selectedAppearanceTab === AppearanceTab.Species ||
        (selectedAppearanceTab === AppearanceTab.Hair && species_has_hair) ||
        (selectedAppearanceTab === AppearanceTab.FacialHair && species_has_facial_hair) ||
        (selectedAppearanceTab === AppearanceTab.Wings && species_has_wings) ||
        selectedAppearanceTab === AppearanceTab.Clothing ||
        selectedAppearanceTab === AppearanceTab.Prosthetics;

      if (!isCurrentTabValid) {
        setSelectedAppearanceTab(AppearanceTab.General);
      }
    }
    setPreviousSpecies(species);
  }, [species, selectedAppearanceTab, species_has_hair, species_has_facial_hair, species_has_wings, previousSpecies]);

  // Helper function to check if a tab should be shown based on species
  const isTabVisible = (tab: AppearanceTab) => {
    switch (tab) {
      case AppearanceTab.General:
        return true;
      case AppearanceTab.Hair:
        return species_has_hair;
      case AppearanceTab.FacialHair:
        return species_has_facial_hair;
      case AppearanceTab.Wings:
        return species_has_wings;
      case AppearanceTab.Clothing:
        return true;
      case AppearanceTab.Prosthetics:
        return true;
      default:
        return false;
    }
  };

  return (
    <Stack fill vertical>
      {/* Top row: Three column layout */}
      <Stack.Item>
        <Stack fill>
          {/* Column 1: Character preview - front facing and side facing */}
          <Stack.Item>
            <CharacterPreview has_preview={has_preview} preview_timestamp={preview_timestamp} />
          </Stack.Item>
          {/* Column 2: Basic information */}
          <Stack.Item basis="200px" ml={2}>
            {basic_information && <BasicInformation data={basic_information} />}
          </Stack.Item>
          {/* Column 3: Available for future content */}
          <Stack.Item grow ml={2}>
            <Box
              style={{
                height: '140px',
                border: '1px dashed #444',
                borderRadius: '4px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#666',
                fontStyle: 'italic',
              }}
            >
              Available for additional content
            </Box>
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Main content section with tabs */}
      <Stack.Item grow>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={selectedMainTab === Tab.Appearance}
                onClick={() => setSelectedMainTab(Tab.Appearance)}
              >
                Appearance
              </Tabs.Tab>
              <Tabs.Tab
                selected={selectedMainTab === Tab.Background}
                onClick={() => setSelectedMainTab(Tab.Background)}
              >
                Background
              </Tabs.Tab>
              <Tabs.Tab selected={selectedMainTab === Tab.Loadout} onClick={() => setSelectedMainTab(Tab.Loadout)}>
                Loadout
              </Tabs.Tab>
              <Tabs.Tab selected={selectedMainTab === Tab.Quirks} onClick={() => setSelectedMainTab(Tab.Quirks)}>
                Quirks
              </Tabs.Tab>
              <Tabs.Tab
                selected={selectedMainTab === Tab.JobPreferences}
                onClick={() => setSelectedMainTab(Tab.JobPreferences)}
              >
                Job Preferences
              </Tabs.Tab>
              <Tabs.Tab
                selected={selectedMainTab === Tab.AntagPreferences}
                onClick={() => setSelectedMainTab(Tab.AntagPreferences)}
              >
                Antag Preferences
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {selectedMainTab === Tab.Appearance && (
              <Section title="Appearance" fill>
                <Stack fill vertical>
                  <Stack.Item>
                    <Tabs>
                      <Tabs.Tab
                        selected={selectedAppearanceTab === AppearanceTab.General}
                        onClick={() => setSelectedAppearanceTab(AppearanceTab.General)}
                      >
                        General
                      </Tabs.Tab>
                      <Tabs.Tab
                        selected={selectedAppearanceTab === AppearanceTab.Species}
                        onClick={() => setSelectedAppearanceTab(AppearanceTab.Species)}
                      >
                        Species
                      </Tabs.Tab>
                      {isTabVisible(AppearanceTab.Hair) ? (
                        <Tabs.Tab
                          selected={selectedAppearanceTab === AppearanceTab.Hair}
                          onClick={() => setSelectedAppearanceTab(AppearanceTab.Hair)}
                        >
                          Hair
                        </Tabs.Tab>
                      ) : null}
                      {isTabVisible(AppearanceTab.FacialHair) ? (
                        <Tabs.Tab
                          selected={selectedAppearanceTab === AppearanceTab.FacialHair}
                          onClick={() => setSelectedAppearanceTab(AppearanceTab.FacialHair)}
                        >
                          Facial Hair
                        </Tabs.Tab>
                      ) : null}
                      {isTabVisible(AppearanceTab.Wings) ? (
                        <Tabs.Tab
                          selected={selectedAppearanceTab === AppearanceTab.Wings}
                          onClick={() => setSelectedAppearanceTab(AppearanceTab.Wings)}
                        >
                          Wings
                        </Tabs.Tab>
                      ) : null}
                      <Tabs.Tab
                        selected={selectedAppearanceTab === AppearanceTab.Clothing}
                        onClick={() => setSelectedAppearanceTab(AppearanceTab.Clothing)}
                      >
                        Clothing
                      </Tabs.Tab>
                      <Tabs.Tab
                        selected={selectedAppearanceTab === AppearanceTab.Prosthetics}
                        onClick={() => setSelectedAppearanceTab(AppearanceTab.Prosthetics)}
                      >
                        Prosthetics
                      </Tabs.Tab>
                    </Tabs>
                  </Stack.Item>
                  <Stack.Item grow>
                    {getAppearanceTabContent(selectedAppearanceTab, {
                      species_selection,
                      available_hair_styles,
                      available_facial_hair_styles,
                      available_hair_gradients,
                      available_wings,
                      available_underwear,
                      available_undershirt,
                      available_socks,
                      available_backpack_types,
                      h_style,
                      h_colour,
                      h_sec_colour,
                      h_gradient_style,
                      h_gradient_colour,
                      f_style,
                      f_colour,
                      f_sec_colour,
                      wing_style,
                      body_type,
                      e_colour,
                      s_colour,
                      underwear,
                      undershirt,
                      socks,
                      backbag,
                      act,
                    })}
                  </Stack.Item>
                </Stack>
              </Section>
            )}
            {selectedMainTab === Tab.Background && <BackgroundTab />}
            {selectedMainTab === Tab.Loadout && <LoadoutTab />}
            {selectedMainTab === Tab.Quirks && <QuirksTab />}
            {selectedMainTab === Tab.JobPreferences && <JobTab />}
            {selectedMainTab === Tab.AntagPreferences && <AntagPreferencesTab />}
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const getAppearanceTabContent = (tab: AppearanceTab, props: any) => {
  switch (tab) {
    case AppearanceTab.General:
      return <GeneralSubTab {...props} />;
    case AppearanceTab.Species:
      return props.species_selection ? <SpeciesSelection data={props.species_selection} /> : null;
    case AppearanceTab.Hair:
      return <HairSubTab {...props} />;
    case AppearanceTab.FacialHair:
      return <FacialHairSubTab {...props} />;
    case AppearanceTab.Wings:
      return <WingsSubTab {...props} />;
    case AppearanceTab.Clothing:
      return <ClothingSubTab {...props} />;
    case AppearanceTab.Prosthetics:
      return <ProstheticsSubTab {...props} />;
    default:
      return <GeneralSubTab {...props} />;
  }
};

const selectHairStyles = (styles: HairStyle[], searchText = '') => {
  const testSearch = createSearch(searchText, (style: HairStyle) => style.name);
  return styles.filter(testSearch);
};

const HairSubTab = (props) => {
  const {
    available_hair_styles,
    available_hair_gradients,
    h_style,
    h_colour,
    h_sec_colour,
    h_gradient_style,
    h_gradient_colour,
    act,
  } = props;
  const [searchText, setSearchText] = useState('');
  const filtered_hair_styles = selectHairStyles(available_hair_styles || [], searchText);

  return (
    <Stack fill>
      {/* Left panel - Colors and gradients */}
      <Stack.Item basis="300px">
        <Stack fill vertical>
          <Stack.Item>
            <Section title="Hair Colors">
              <LabeledList>
                <LabeledList.Item label="Primary Color">
                  <Button
                    onClick={() => act('set_hair_color')}
                    style={{
                      backgroundColor: h_colour,
                      border: '1px solid #ccc',
                      width: '60px',
                      height: '20px',
                    }}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Secondary Color">
                  <Button
                    onClick={() => act('set_secondary_hair_color')}
                    style={{
                      backgroundColor: h_sec_colour,
                      border: '1px solid #ccc',
                      width: '60px',
                      height: '20px',
                    }}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Hair Gradients">
              <LabeledList>
                <LabeledList.Item label="Gradient Style">
                  <Dropdown
                    width="180px"
                    selected={h_gradient_style || 'None'}
                    options={available_hair_gradients?.map((g) => g.name) || ['None']}
                    onSelected={(value) =>
                      act('set_hair_gradient', {
                        gradient: value,
                      })
                    }
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Gradient Color">
                  <Button
                    onClick={() => act('set_hair_gradient_color')}
                    style={{
                      backgroundColor: h_gradient_colour,
                      border: '1px solid #ccc',
                      width: '60px',
                      height: '20px',
                    }}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Right panel - hair style grid */}
      <Stack.Item grow>
        <Stack fill vertical>
          <Stack.Item>
            <Input
              fluid
              placeholder="Search for a hair style"
              value={searchText}
              onChange={(value) => setSearchText(value)}
            />
          </Stack.Item>
          <Stack.Item grow>
            <Box
              height="400px"
              overflowY="auto"
              style={{ border: '1px solid #666', borderRadius: '4px', padding: '8px' }}
            >
              {filtered_hair_styles.map((hair_style) => {
                const style_key = `${hair_style.name}_${hair_style.icon_state}`;
                const is_selected = style_key === h_style || hair_style.name === h_style;
                return (
                  <Box
                    key={style_key}
                    style={{
                      display: 'inline-flex',
                      flexDirection: 'column',
                      justifyContent: 'space-between',
                      margin: '4px',
                      padding: '4px',
                      border: is_selected ? '2px solid #4a9eff' : '1px solid #666',
                      borderRadius: '4px',
                      backgroundColor: 'rgba(128, 128, 128, 0.4)',
                      textAlign: 'center',
                      width: '80px',
                      height: '100px',
                      transition: 'all 0.2s ease',
                      overflow: 'hidden',
                      cursor: 'pointer',
                    }}
                    onClick={() => {
                      act('set_hair_style', {
                        style: hair_style.name,
                      });
                    }}
                  >
                    <div
                      style={{
                        width: '64px',
                        height: '64px',
                        border: '2px solid transparent',
                        borderRadius: '4px',
                        display: 'flex',
                        alignItems: 'flex-start',
                        justifyContent: 'center',
                        flex: '0 0 auto',
                        overflow: 'hidden',
                        pointerEvents: 'none',
                      }}
                    >
                      <img
                        src={hair_style.icon}
                        alt={hair_style.name}
                        style={{
                          width: '128px',
                          height: '128px',
                          imageRendering: 'pixelated',
                          marginTop: '0px',
                          marginLeft: '4px',
                        }}
                        onError={(e) => {
                          console.log(`Failed to load hair style image: ${hair_style.icon}`);
                        }}
                      />
                    </div>
                    <div
                      style={{
                        fontSize: '9px',
                        fontFamily: 'Verdana, Arial, sans-serif',
                        fontWeight: is_selected ? 'bold' : 'normal',
                        wordWrap: 'break-word',
                        color: '#ffffff',
                        textShadow: '1px 1px 2px rgba(0,0,0,0.8)',
                        height: '20px',
                        lineHeight: '10px',
                        overflow: 'hidden',
                        textAlign: 'center',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flex: '0 0 auto',
                      }}
                    >
                      {hair_style.name}
                    </div>
                  </Box>
                );
              })}
            </Box>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const SpeciesSection = () => {
  const { act, data } = useBackend<CharacterCreatorData>();
  const { species, species_info = {} } = data;
  const [selectedSpecies, setSelectedSpecies] = useState(species || '');

  const availableSpecies = Object.keys(species_info);
  const currentSpeciesInfo = species_info[selectedSpecies] || { name: '', description: '' };

  const handleSpeciesChange = (newSpecies: string) => {
    setSelectedSpecies(newSpecies);
    act('set_species', { species: newSpecies });
  };

  return (
    <Section title="Species">
      <Stack
        fill
        style={{
          height: '300px',
        }}
      >
        {/* Species list on the left */}
        <Stack.Item basis="40%">
          <Section fill scrollable>
            <Stack vertical>
              {availableSpecies.map((speciesName) => {
                const speciesData = species_info[speciesName];
                return (
                  <Stack.Item key={speciesName}>
                    <Button
                      fluid
                      selected={selectedSpecies === speciesName}
                      onClick={() => handleSpeciesChange(speciesName)}
                      style={{
                        textAlign: 'left',
                        justifyContent: 'flex-start',
                      }}
                    >
                      {speciesData.name}
                    </Button>
                  </Stack.Item>
                );
              })}
            </Stack>
          </Section>
        </Stack.Item>

        {/* Species description on the right */}
        <Stack.Item basis="60%">
          <Section fill>
            <Stack
              fill
              style={{
                justifyContent: 'center',
                alignItems: 'center',
              }}
            >
              <Stack.Item>
                <Box
                  style={{
                    padding: '16px',
                    lineHeight: '1.5',
                    fontSize: '13px',
                    textAlign: 'left',
                    maxWidth: '100%',
                  }}
                >
                  {currentSpeciesInfo.description ? (
                    <Box
                      style={{
                        fontFamily: 'Verdana, Arial, sans-serif',
                        whiteSpace: 'pre-wrap',
                      }}
                    >
                      {currentSpeciesInfo.description.replace(/<br\/><br\/>/g, '\n\n').replace(/<.*?>/g, '')}
                    </Box>
                  ) : (
                    <Box color="label" style={{ fontStyle: 'italic' }}>
                      Select a species to view its description.
                    </Box>
                  )}
                </Box>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const GeneralSubTab = (props) => {
  const {
    e_colour,
    s_colour,
    body_type,
    physique,
    height,
    runechat_color,
    available_physiques,
    available_heights,
    act,
  } = props;

  return (
    <Stack fill vertical>
      <Stack.Item grow>
        <Stack fill>
          <Stack.Item basis="33%">
            <LabeledList>
              <LabeledList.Item label="Body Type">
                <Stack>
                  <Stack.Item>
                    <Button
                      selected={body_type === 'masculine'}
                      onClick={() =>
                        act('set_body_type', {
                          body_type: 'masculine',
                        })
                      }
                    >
                      Masculine
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      selected={body_type === 'feminine'}
                      onClick={() =>
                        act('set_body_type', {
                          body_type: 'feminine',
                        })
                      }
                    >
                      Feminine
                    </Button>
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>
            </LabeledList>
          </Stack.Item>
          <Stack.Item basis="33%">
            <LabeledList>
              <LabeledList.Item label="Eye Color">
                <Button
                  onClick={() => act('set_eye_color')}
                  style={{
                    backgroundColor: e_colour,
                    border: '1px solid #ccc',
                    width: '60px',
                    height: '20px',
                  }}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Runechat Color">
                <Stack>
                  <Stack.Item>
                    <Button
                      onClick={() => act('set_runechat_color')}
                      style={{
                        backgroundColor: runechat_color || '#ffffff',
                        border: '1px solid #ccc',
                        width: '60px',
                        height: '20px',
                      }}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <div
                      style={{
                        color: runechat_color || '#ffffff',
                        fontSize: '12px',
                        fontFamily: 'monospace',
                        fontWeight: 'bold',
                        lineHeight: '1.1',
                        textShadow:
                          '1px 1px 0px #000000, -1px 1px 0px #000000, 1px -1px 0px #000000, -1px -1px 0px #000000',
                        padding: '2px 4px',
                        imageRendering: 'pixelated',
                      }}
                    >
                      Runechat looks like this
                    </div>
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>
            </LabeledList>
          </Stack.Item>
          <Stack.Item basis="33%">
            <LabeledList>
              <LabeledList.Item label="Body Color">
                <Button
                  onClick={() => act('set_skin_color')}
                  style={{
                    backgroundColor: s_colour,
                    border: '1px solid #ccc',
                    width: '60px',
                    height: '20px',
                  }}
                />
              </LabeledList.Item>
            </LabeledList>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const FacialHairSubTab = (props) => {
  const { available_facial_hair_styles, f_style, f_colour, f_sec_colour, act } = props;
  const [searchText, setSearchText] = useState('');
  const filtered_facial_hair_styles = selectHairStyles(available_facial_hair_styles || [], searchText);

  return (
    <Stack fill>
      {/* Left panel - colors */}
      <Stack.Item basis="300px">
        <Section title="Facial Hair Colors">
          <LabeledList>
            <LabeledList.Item label="Primary Color">
              <Button
                onClick={() => act('set_facial_hair_color')}
                style={{
                  backgroundColor: f_colour,
                  border: '1px solid #ccc',
                  width: '60px',
                  height: '20px',
                }}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Secondary Color">
              <Button
                onClick={() => act('set_secondary_facial_hair_color')}
                style={{
                  backgroundColor: f_sec_colour,
                  border: '1px solid #ccc',
                  width: '60px',
                  height: '20px',
                }}
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      {/* Right panel - facial hair style grid */}
      <Stack.Item grow>
        <Stack fill vertical>
          <Stack.Item>
            <Input
              fluid
              placeholder="Search for a facial hair style"
              value={searchText}
              onChange={(value) => setSearchText(value)}
            />
          </Stack.Item>
          <Stack.Item grow>
            <Box
              height="400px"
              overflowY="auto"
              style={{ border: '1px solid #666', borderRadius: '4px', padding: '8px' }}
            >
              {filtered_facial_hair_styles.map((hair_style) => {
                const style_key = `${hair_style.name}_${hair_style.icon_state}`;
                const is_selected = style_key === f_style || hair_style.name === f_style;
                return (
                  <Box
                    key={style_key}
                    style={{
                      display: 'inline-flex',
                      flexDirection: 'column',
                      justifyContent: 'space-between',
                      margin: '4px',
                      padding: '4px',
                      border: is_selected ? '2px solid #4a9eff' : '1px solid #666',
                      borderRadius: '4px',
                      backgroundColor: 'rgba(128, 128, 128, 0.4)',
                      textAlign: 'center',
                      width: '80px',
                      height: '100px',
                      transition: 'all 0.2s ease',
                      overflow: 'hidden',
                      cursor: 'pointer',
                    }}
                    onClick={() => {
                      act('set_facial_hair_style', {
                        style: hair_style.name,
                      });
                    }}
                  >
                    <div
                      style={{
                        width: '64px',
                        height: '64px',
                        border: '2px solid transparent',
                        borderRadius: '4px',
                        display: 'flex',
                        alignItems: 'flex-start',
                        justifyContent: 'center',
                        flex: '0 0 auto',
                        overflow: 'hidden',
                        pointerEvents: 'none',
                      }}
                    >
                      <img
                        src={hair_style.icon}
                        alt={hair_style.name}
                        style={{
                          width: '128px',
                          height: '128px',
                          imageRendering: 'pixelated',
                          marginTop: '-16px',
                          marginLeft: '4px',
                        }}
                        onError={(e) => {
                          console.log(`Failed to load facial hair style image: ${hair_style.icon}`);
                        }}
                      />
                    </div>
                    <div
                      style={{
                        fontSize: '9px',
                        fontFamily: 'Verdana, Arial, sans-serif',
                        fontWeight: is_selected ? 'bold' : 'normal',
                        wordWrap: 'break-word',
                        color: '#ffffff',
                        textShadow: '1px 1px 2px rgba(0,0,0,0.8)',
                        height: '20px',
                        lineHeight: '10px',
                        overflow: 'hidden',
                        textAlign: 'center',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flex: '0 0 auto',
                      }}
                    >
                      {hair_style.name}
                    </div>
                  </Box>
                );
              })}
            </Box>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

// Nian wings sub-tab - all one panel
const WingsSubTab = (props) => {
  const { available_wings = [], wing_style, act } = props;
  const [searchText, setSearchText] = useState('');

  // Filter wings based on search text
  const filteredWings = available_wings.filter((wing) => wing.name.toLowerCase().includes(searchText.toLowerCase()));

  return (
    <Stack fill>
      <Stack.Item grow>
        <Section title="Wing Style">
          <Stack vertical>
            <Stack.Item>
              <Input
                placeholder="Search wing styles..."
                value={searchText}
                onChange={(value) => setSearchText(value)}
                fluid
              />
            </Stack.Item>
            <Stack.Item>
              <Box
                height="400px"
                overflow="auto"
                style={{ border: '1px solid #666', borderRadius: '4px', padding: '8px' }}
              >
                {filteredWings.map((wing_style_item, index) => {
                  const style_key = `${wing_style_item.name}_${wing_style_item.icon_state}`;
                  const is_selected =
                    wing_style_item.name === wing_style || (!wing_style && wing_style_item.name === 'None');
                  return (
                    <Box
                      key={wing_style_item.name || index}
                      style={{
                        display: 'inline-flex',
                        flexDirection: 'column',
                        justifyContent: 'space-between',
                        margin: '4px',
                        padding: '4px',
                        border: is_selected ? '2px solid #4a9eff' : '1px solid #666',
                        borderRadius: '4px',
                        backgroundColor: 'rgba(128, 128, 128, 0.4)',
                        textAlign: 'center',
                        width: '80px',
                        height: '100px',
                        transition: 'all 0.2s ease',
                        overflow: 'hidden',
                        cursor: 'pointer',
                      }}
                      onClick={() =>
                        act('set_wing_style', {
                          wing_style: wing_style_item.name,
                        })
                      }
                    >
                      <div
                        style={{
                          width: '64px',
                          height: '64px',
                          border: '2px solid transparent',
                          borderRadius: '4px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          flex: '0 0 auto',
                          overflow: 'hidden',
                          pointerEvents: 'none',
                        }}
                      >
                        {wing_style_item.icon ? (
                          <img
                            src={wing_style_item.icon}
                            alt={wing_style_item.name}
                            style={{
                              width: '128px',
                              height: '128px',
                              imageRendering: 'pixelated',
                              objectFit: 'contain',
                              marginTop: '0px',
                              marginLeft: '4px',
                            }}
                          />
                        ) : (
                          <div
                            style={{
                              width: '48px',
                              height: '48px',
                              backgroundColor: '#333',
                              border: '2px solid #555',
                              borderRadius: '4px',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontSize: '10px',
                              color: '#ccc',
                            }}
                          >
                            None
                          </div>
                        )}
                      </div>
                      <div
                        style={{
                          fontSize: '9px',
                          fontFamily: 'Verdana, Arial, sans-serif',
                          fontWeight: 'bold',
                          color: '#fff',
                          textShadow: '1px 1px 1px #000',
                          lineHeight: '1.1',
                          maxHeight: '28px',
                          overflow: 'hidden',
                          wordBreak: 'break-word',
                          hyphens: 'auto',
                          textAlign: 'center',
                          padding: '1px',
                          pointerEvents: 'none',
                        }}
                      >
                        {wing_style_item.name}
                      </div>
                    </Box>
                  );
                })}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

// Prosthetics - for everyone but machines, this is arms and legs; for machines, includes head and chest too
const ProstheticsSubTab = (props) => {
  const { act, data } = useBackend<CharacterCreatorData>();
  const [selectedProstheticsCategory, setSelectedProstheticsCategory] = useState<ProstheticsCategory>(
    ProstheticsCategory.LeftArm
  );

  const { available_prosthetics = {}, prosthetic_states = {}, is_machine_species = false } = data;

  const getProstheticsDisplayName = (category: ProstheticsCategory) => {
    switch (category) {
      case ProstheticsCategory.Head:
        return 'Head';
      case ProstheticsCategory.LeftArm:
        return 'Left Arm';
      case ProstheticsCategory.RightArm:
        return 'Right Arm';
      case ProstheticsCategory.LeftHand:
        return 'Left Hand';
      case ProstheticsCategory.RightHand:
        return 'Right Hand';
      case ProstheticsCategory.LeftLeg:
        return 'Left Leg';
      case ProstheticsCategory.RightLeg:
        return 'Right Leg';
      case ProstheticsCategory.LeftFoot:
        return 'Left Foot';
      case ProstheticsCategory.RightFoot:
        return 'Right Foot';
      case ProstheticsCategory.Chest:
        return 'Chest';
      default:
        return 'Unknown';
    }
  };

  const getProstheticsPartName = (category: ProstheticsCategory) => {
    switch (category) {
      case ProstheticsCategory.Head:
        return 'head';
      case ProstheticsCategory.LeftArm:
        return 'l_arm';
      case ProstheticsCategory.RightArm:
        return 'r_arm';
      case ProstheticsCategory.LeftHand:
        return 'l_hand';
      case ProstheticsCategory.RightHand:
        return 'r_hand';
      case ProstheticsCategory.LeftLeg:
        return 'l_leg';
      case ProstheticsCategory.RightLeg:
        return 'r_leg';
      case ProstheticsCategory.LeftFoot:
        return 'l_foot';
      case ProstheticsCategory.RightFoot:
        return 'r_foot';
      case ProstheticsCategory.Chest:
        return 'chest';
      default:
        return 'head';
    }
  };

  const isCategoryAvailable = (category: ProstheticsCategory) => {
    // Head and chest only available for machines
    const machineOnlyCategories = [ProstheticsCategory.Head, ProstheticsCategory.Chest];
    if (machineOnlyCategories.includes(category)) {
      return is_machine_species;
    }
    return true;
  };

  const getAvailableCategories = () => {
    return Object.values(ProstheticsCategory)
      .filter((cat) => typeof cat === 'number' && isCategoryAvailable(cat as ProstheticsCategory))
      .map((cat) => cat as ProstheticsCategory);
  };

  const getCurrentProstheticsData = () => {
    const partName = getProstheticsPartName(selectedProstheticsCategory);
    return available_prosthetics[partName] || [];
  };

  const partName = getProstheticsPartName(selectedProstheticsCategory);
  const currentProsthetic = prosthetic_states[partName] || (is_machine_species ? 'Morpheus Cyberkinetics' : 'none');

  // Set default category to first available one
  const availableCategories = getAvailableCategories();
  if (availableCategories.length > 0 && !isCategoryAvailable(selectedProstheticsCategory)) {
    setSelectedProstheticsCategory(availableCategories[0]);
  }

  return (
    <Section title="Prosthetics" fill>
      <Stack fill>
        {/* Left panel - category selection */}
        <Stack.Item basis="200px">
          <Section title="Body Part">
            <Stack vertical>
              {availableCategories.map((category) => (
                <Stack.Item key={category}>
                  <Button
                    fluid
                    color={selectedProstheticsCategory === category ? 'blue' : undefined}
                    onClick={() => setSelectedProstheticsCategory(category)}
                  >
                    {getProstheticsDisplayName(category)}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          </Section>
        </Stack.Item>

        {/* Right panel - prosthetic selection */}
        <Stack.Item grow>
          <Section title={getProstheticsDisplayName(selectedProstheticsCategory)}>
            {!getCurrentProstheticsData() || !Array.isArray(getCurrentProstheticsData()) ? (
              <Box>Loading options...</Box>
            ) : (
              <Box
                height="400px"
                overflow="auto"
                style={{ border: '1px solid #666', borderRadius: '4px', padding: '8px' }}
              >
                {getCurrentProstheticsData().map((prosthetic, index) => {
                  const is_selected = currentProsthetic === prosthetic.value;
                  return (
                    <Box
                      key={prosthetic.value || index}
                      style={{
                        display: 'inline-flex',
                        flexDirection: 'column',
                        justifyContent: 'space-between',
                        margin: '4px',
                        padding: '4px',
                        border: is_selected ? '2px solid #4a9eff' : '1px solid #666',
                        borderRadius: '4px',
                        backgroundColor: 'rgba(128, 128, 128, 0.4)',
                        textAlign: 'center',
                        width: '80px',
                        height: '100px',
                        transition: 'all 0.2s ease',
                        overflow: 'hidden',
                        cursor: 'pointer',
                      }}
                      onClick={() =>
                        act('set_prosthetic', {
                          part: partName,
                          value: prosthetic.value,
                        })
                      }
                    >
                      <div
                        style={{
                          width: '64px',
                          height: '64px',
                          border: '2px solid transparent',
                          borderRadius: '4px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          flex: '0 0 auto',
                          overflow: 'hidden',
                          pointerEvents: 'none',
                        }}
                      >
                        {prosthetic.icon ? (
                          <img
                            src={prosthetic.icon}
                            style={{
                              width: '128px',
                              height: '128px',
                              imageRendering: 'pixelated',
                              objectFit: 'contain',
                              marginTop: '-32px',
                              marginLeft: '4px',
                            }}
                            alt={prosthetic.name}
                          />
                        ) : (
                          <div
                            style={{
                              width: '48px',
                              height: '48px',
                              backgroundColor: prosthetic.value === 'amputated' ? '#660000' : '#333',
                              border: prosthetic.value === 'amputated' ? '2px solid #990000' : '2px solid #555',
                              borderRadius: '4px',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontSize: '10px',
                              color: prosthetic.value === 'amputated' ? '#ff6666' : '#ccc',
                            }}
                          >
                            {prosthetic.value === 'amputated' ? 'Missing' : 'Intact'}
                          </div>
                        )}
                      </div>
                      <div
                        style={{
                          fontSize: '9px',
                          fontFamily: 'Verdana, Arial, sans-serif',
                          fontWeight: 'bold',
                          color: '#fff',
                          textShadow: '1px 1px 1px #000',
                          lineHeight: '1.1',
                          maxHeight: '28px',
                          overflow: 'hidden',
                          wordBreak: 'break-word',
                          hyphens: 'auto',
                          textAlign: 'center',
                          padding: '1px',
                          pointerEvents: 'none',
                        }}
                      >
                        {prosthetic.name}
                      </div>
                    </Box>
                  );
                })}
              </Box>
            )}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// Clothes - everyone gets this
const ClothingSubTab = (props) => {
  const {
    available_underwear,
    available_undershirt,
    available_socks,
    available_backpack_types,
    underwear,
    undershirt,
    socks,
    backbag,
    act,
  } = props;

  const [selectedClothingCategory, setSelectedClothingCategory] = useState<ClothingCategory>(
    ClothingCategory.Underwear
  );

  const getCurrentClothingData = () => {
    switch (selectedClothingCategory) {
      case ClothingCategory.Underwear:
        return { items: available_underwear, current: underwear, action: 'set_underwear', param: 'underwear' };
      case ClothingCategory.Undershirt:
        return { items: available_undershirt, current: undershirt, action: 'set_undershirt', param: 'undershirt' };
      case ClothingCategory.Socks:
        return { items: available_socks, current: socks, action: 'set_socks', param: 'socks' };
      case ClothingCategory.Backpack:
        return { items: available_backpack_types, current: backbag, action: 'set_backpack', param: 'backpack' };
      default:
        return { items: [], current: '', action: '', param: '' };
    }
  };

  const clothingData = getCurrentClothingData();
  const isBackpackCategory = selectedClothingCategory === ClothingCategory.Backpack;

  return (
    <Section title="Clothing" fill>
      <Stack fill>
        {/* Left panel - category selection (underwear, undershirt, socks, backpack) */}
        <Stack.Item basis="200px">
          <Section title="Category">
            <Stack vertical>
              <Stack.Item>
                <Button
                  fluid
                  color={selectedClothingCategory === ClothingCategory.Underwear ? 'blue' : undefined}
                  onClick={() => setSelectedClothingCategory(ClothingCategory.Underwear)}
                >
                  Underwear
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  fluid
                  color={selectedClothingCategory === ClothingCategory.Undershirt ? 'blue' : undefined}
                  onClick={() => setSelectedClothingCategory(ClothingCategory.Undershirt)}
                >
                  Undershirt
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  fluid
                  color={selectedClothingCategory === ClothingCategory.Socks ? 'blue' : undefined}
                  onClick={() => setSelectedClothingCategory(ClothingCategory.Socks)}
                >
                  Socks
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  fluid
                  color={selectedClothingCategory === ClothingCategory.Backpack ? 'blue' : undefined}
                  onClick={() => setSelectedClothingCategory(ClothingCategory.Backpack)}
                >
                  Backpack Type
                </Button>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>

        {/* Right panel - item selection */}
        <Stack.Item grow>
          <Section
            title={
              selectedClothingCategory === ClothingCategory.Underwear
                ? 'Underwear'
                : selectedClothingCategory === ClothingCategory.Undershirt
                  ? 'Undershirt'
                  : selectedClothingCategory === ClothingCategory.Socks
                    ? 'Socks'
                    : 'Backpack Type'
            }
          >
            {!clothingData.items || !Array.isArray(clothingData.items) ? (
              <Box>Loading options...</Box>
            ) : isBackpackCategory ? (
              // Backpack types as simple buttons for now
              <Stack vertical>
                {clothingData.items.map((item, index) => (
                  <Stack.Item key={item.name || index} m={1}>
                    <Button
                      fluid
                      color={clothingData.current === item.name ? 'blue' : undefined}
                      onClick={() => act(clothingData.action, { [clothingData.param]: item.name })}
                    >
                      {item.name}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            ) : (
              <Box
                height="400px"
                overflow="auto"
                style={{ border: '1px solid #666', borderRadius: '4px', padding: '8px' }}
              >
                {clothingData.items.map((item) => {
                  const is_selected = clothingData.current === item.name;
                  return (
                    <Box
                      key={item.name}
                      style={{
                        display: 'inline-flex',
                        flexDirection: 'column',
                        justifyContent: 'space-between',
                        margin: '4px',
                        padding: '4px',
                        border: is_selected ? '2px solid #4a9eff' : '1px solid #666',
                        borderRadius: '4px',
                        backgroundColor: 'rgba(128, 128, 128, 0.4)',
                        textAlign: 'center',
                        width: '80px',
                        height: '100px',
                        transition: 'all 0.2s ease',
                        overflow: 'hidden',
                        cursor: 'pointer',
                      }}
                      onClick={() => act(clothingData.action, { [clothingData.param]: item.name })}
                    >
                      <div
                        style={{
                          width: '64px',
                          height: '64px',
                          border: '2px solid transparent',
                          borderRadius: '4px',
                          display: 'flex',
                          alignItems: 'flex-start',
                          justifyContent: 'center',
                          flex: '0 0 auto',
                          overflow: 'hidden',
                          pointerEvents: 'none',
                        }}
                      >
                        <img
                          src={item.icon}
                          alt={item.name}
                          style={{
                            width: '128px',
                            height: '128px',
                            imageRendering: 'pixelated',
                            marginTop:
                              selectedClothingCategory === ClothingCategory.Undershirt
                                ? '-32px'
                                : selectedClothingCategory === ClothingCategory.Underwear
                                  ? '-48px'
                                  : '-64px',
                            marginLeft: '4px',
                          }}
                        />
                      </div>
                      <div
                        style={{
                          fontSize: '9px',
                          fontFamily: 'Verdana, Arial, sans-serif',
                          fontWeight: 'bold',
                          color: '#fff',
                          textShadow: '1px 1px 1px #000',
                          lineHeight: '1.1',
                          maxHeight: '28px',
                          overflow: 'hidden',
                          wordBreak: 'break-word',
                          hyphens: 'auto',
                          textAlign: 'center',
                          padding: '1px',
                          pointerEvents: 'none',
                        }}
                      >
                        {item.name}
                      </div>
                    </Box>
                  );
                })}
              </Box>
            )}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const JobTab = (props) => {
  return <Section title="Job Preferences" fill />;
};

// Bottom mounted action buttons
const CharacterActions = (props) => {
  const { act, data } = useBackend<CharacterData>();

  return (
    <Section>
      <Stack fill>
        <Stack.Item>
          <Button icon="dice" onClick={() => act('randomize_all')}>
            Randomize All
          </Button>
        </Stack.Item>
        <Stack.Item grow />
        <Stack.Item>
          <Button onClick={() => act('close')}>Close</Button>
        </Stack.Item>
        <Stack.Item>
          <Button color="good" onClick={() => act('save')}>
            Save Changes
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// Sort functions for loadout gear
const sortTypes = {
  'Default': (a, b) => a.gear.gear_tier - b.gear.gear_tier,
  'Alphabetical': (a, b) => a.gear.name.toLowerCase().localeCompare(b.gear.name.toLowerCase()),
  'Cost': (a, b) => a.gear.cost - b.gear.cost,
};

const LoadoutTab = (props) => {
  const { act, data } = useBackend<CharacterCreatorData>();
  const [search, setSearch] = useState(false);
  const [searchText, setSearchText] = useState('');
  const [category, setCategory] = useState(data.gears ? Object.keys(data.gears)[0] : '');

  if (!data.gears) {
    return (
      <Section title="Loadout" fill>
        <Box textAlign="center" color="label" p={4}>
          Loading loadout data...
        </Box>
      </Section>
    );
  }

  return (
    <Section title="Loadout" fill>
      <Stack fill vertical>
        <Stack.Item>
          <LoadoutCategories category={category} setCategory={setCategory} />
        </Stack.Item>
        <Stack.Item grow>
          <Stack fill>
            <Stack.Item basis="25%">
              <LoadoutEquipped />
            </Stack.Item>
            <Stack.Item basis="75%">
              <LoadoutGears
                category={category}
                search={search}
                setSearch={setSearch}
                searchText={searchText}
                setSearchText={setSearchText}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const LoadoutCategories = (props) => {
  const { act, data } = useBackend<CharacterCreatorData>();
  const { category, setCategory } = props;
  return (
    <Tabs fluid textAlign="center" style={{ flexWrap: 'wrap-reverse' }}>
      {Object.keys(data.gears || {}).map((cat) => (
        <Tabs.Tab
          key={cat}
          selected={cat === category}
          style={{
            whiteSpace: 'nowrap',
          }}
          onClick={() => setCategory(cat)}
        >
          {cat}
        </Tabs.Tab>
      ))}
    </Tabs>
  );
};

const LoadoutGears = (props) => {
  const { act, data } = useBackend<CharacterCreatorData>();
  const { user_tier = 0, gear_slots = 0, max_gear_slots = 0 } = data;
  const { category, search, setSearch, searchText, setSearchText } = props;

  const [sortType, setSortType] = useState('Default');
  const [sortReverse, setSortReverse] = useState(false);
  const testSearch = createSearch<Gear>(searchText, (gear) => gear.name);

  let contents;
  if (searchText.length > 2) {
    contents = Object.entries(data.gears || {})
      .reduce<{ key: string; gear: Gear }[]>((a, [key, gears]) => {
        return a.concat(Object.entries(gears).map(([key, gear]) => ({ key, gear })));
      }, [])
      .filter(({ gear }) => {
        return testSearch(gear);
      });
  } else {
    contents = Object.entries(data.gears?.[category] || {}).map(([key, gear]) => ({ key, gear }));
  }

  contents.sort(sortTypes[sortType]);
  if (sortReverse) {
    contents = contents.reverse();
  }

  return (
    <Section
      fill
      scrollable
      title={category}
      buttons={
        <Stack>
          <Stack.Item>
            <Dropdown
              height={1.66}
              selected={sortType}
              options={Object.keys(sortTypes)}
              onSelected={(value) => setSortType(value)}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon={sortReverse ? 'arrow-down-wide-short' : 'arrow-down-short-wide'}
              tooltip={sortReverse ? 'Ascending order' : 'Descending order'}
              tooltipPosition="bottom-end"
              onClick={() => setSortReverse(!sortReverse)}
            />
          </Stack.Item>
          {search && (
            <Stack.Item>
              <Input width={20} placeholder="Search..." value={searchText} onChange={(value) => setSearchText(value)} />
            </Stack.Item>
          )}
          <Stack.Item>
            <Button
              icon="magnifying-glass"
              selected={search}
              tooltip="Toggle search field"
              tooltipPosition="bottom-end"
              onClick={() => {
                setSearch(!search);
                setSearchText('');
              }}
            />
          </Stack.Item>
        </Stack>
      }
    >
      {contents.map(({ key, gear }) => {
        const maxTextLength = 12;
        const selected = Object.keys(data.selected_gears || {}).includes(key);
        const costText = gear.cost === 1 ? `${gear.cost} Point` : `${gear.cost} Points`;

        const tooltipText = (
          <Box>
            {gear.name.length > maxTextLength && <Box>{gear.name}</Box>}
            {gear.gear_tier > user_tier && (
              <Box mt={gear.name.length > maxTextLength && 1.5} textColor="red">
                That gear is only available at a higher donation tier than you are on.
              </Box>
            )}
          </Box>
        );

        const tooltipsInfo = (
          <>
            {gear.allowed_roles && (
              <Button
                width="22px"
                color="transparent"
                icon="user"
                tooltip={
                  <Section m={-1} title="Allowed Roles">
                    {gear.allowed_roles.map((role) => (
                      <Box key={role}>{role}</Box>
                    ))}
                  </Section>
                }
                tooltipPosition="left"
              />
            )}
            {Object.entries(gear.tweaks).map(([key, tweaks]: [string, Tweak[]]) =>
              tweaks.map((tweak) => (
                <Button
                  key={key}
                  width="22px"
                  color="transparent"
                  icon={tweak.icon}
                  tooltip={tweak.tooltip}
                  tooltipPosition="top"
                />
              ))
            )}
            <Button width="22px" color="transparent" icon="info" tooltip={gear.desc} tooltipPosition="top" />
          </>
        );

        const textInfo = (
          <Box className="Loadout-InfoBox">
            <Box style={{ flexGrow: 1 }} fontSize={1} color="gold" opacity={0.75}>
              {gear.gear_tier > 0 && `Tier ${gear.gear_tier}`}
            </Box>
            <Box fontSize={0.75} opacity={0.66}>
              {costText}
            </Box>
          </Box>
        );

        return (
          <ImageButton
            key={key}
            m={0.5}
            imageSize={84}
            dmIcon={gear.icon}
            dmIconState={gear.icon_state}
            tooltip={(gear.name.length > maxTextLength || gear.gear_tier > 0) && tooltipText}
            tooltipPosition={'bottom'}
            selected={selected}
            disabled={gear.gear_tier > user_tier || (gear_slots + gear.cost > max_gear_slots && !selected)}
            buttons={tooltipsInfo}
            buttonsAlt={textInfo}
            onClick={() => act('toggle_gear', { gear: key })}
          >
            {gear.name}
          </ImageButton>
        );
      })}
    </Section>
  );
};

const LoadoutEquipped = (props) => {
  const { act, data } = useBackend<CharacterCreatorData>();
  const selectedGears = Object.entries(data.gears || {}).reduce<(Gear & { key: string })[]>(
    (a, [categoryKey, categoryItems]) => {
      const selectedInCategory = Object.entries(categoryItems)
        .filter(([gearKey]) => Object.keys(data.selected_gears || {}).includes(gearKey))
        .map(([gearKey, gear]) => ({ key: gearKey, ...gear }));

      return a.concat(selectedInCategory);
    },
    []
  );

  return (
    <Stack fill vertical>
      <Stack.Item grow>
        <Section
          fill
          scrollable
          title={'Selected Equipment'}
          buttons={
            <Button.Confirm
              icon="trash"
              tooltip={'Clear Loadout'}
              tooltipPosition={'bottom-end'}
              onClick={() => act('clear_loadout')}
            />
          }
        >
          {selectedGears.map((gear) => (
            <ImageButton
              key={gear.key}
              fluid
              imageSize={32}
              dmIcon={gear.icon}
              dmIconState={gear.icon_state}
              buttons={
                <>
                  {Object.entries(gear.tweaks).length > 0 && (
                    <Button
                      icon="gears"
                      iconColor="gray"
                      width="33px"
                      onClick={() => act('set_tweak', { gear: gear.key })}
                    />
                  )}
                  <Button
                    icon="times"
                    iconColor="red"
                    width="32px"
                    onClick={() => act('toggle_gear', { gear: gear.key })}
                  />
                </>
              }
            >
              {gear.name}
            </ImageButton>
          ))}
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section>
          <ProgressBar
            value={data.gear_slots || 0}
            maxValue={data.max_gear_slots || 0}
            ranges={{
              bad: [data.max_gear_slots || 0, Infinity],
              average: [(data.max_gear_slots || 0) * 0.66, data.max_gear_slots || 0],
              good: [0, (data.max_gear_slots || 0) * 0.66],
            }}
          >
            <Box textAlign="center">
              Used points {data.gear_slots || 0}/{data.max_gear_slots || 0}
            </Box>
          </ProgressBar>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

// Helper to calculate the balance for a given set of selected quirk names
const calculateBalance = (quirkNames: string[], allQuirks: Quirk[]): number => {
  const selectedSet = new Set(quirkNames);
  return allQuirks.reduce((sum, q) => {
    if (!selectedSet.has(q.name)) return sum;

    return sum + (q.cost < 0 ? Math.abs(q.cost) : -q.cost);
  }, 0);
};

const QuirksTab = (props) => {
  const { act, data } = useBackend<CharacterCreatorData>();

  const selectedQuirks = data.selected_quirks || [];
  const allQuirks = data.all_quirks || [];
  const [selected, setSelected] = useState(selectedQuirks);

  useEffect(() => setSelected(selectedQuirks), [selectedQuirks]);

  const selectedSet = new Set(selected);

  // Calculate the current balance
  const balance = calculateBalance(selected, allQuirks);

  const canAfford = (q: Quirk) => q.cost <= 0 || balance >= q.cost;

  const toggle = (q: Quirk) => {
    const isChosen = selectedSet.has(q.name);

    if (isChosen) {
      const remainingQuirks = selected.filter((n) => n !== q.name);
      const remainingBalance = calculateBalance(remainingQuirks, allQuirks);

      if (q.cost < 0 && remainingBalance < 0) {
        return;
      }
    } else {
      // Logic for ADDING a quirk
      if (q.cost > 0 && !canAfford(q)) {
        return;
      }
    }

    setSelected(isChosen ? selected.filter((n) => n !== q.name) : [...selected, q.name]);
    act(isChosen ? 'remove_quirk' : 'add_quirk', { path: q.path });
  };

  const renderList = (quirks: Quirk[], title: string, color: string, icon: string) => (
    <>
      <Box
        p={0.5}
        mb={1}
        color={color}
        style={{
          border: `1px solid ${color}`,
          backgroundColor: `rgba(${color === 'green' ? '0,128,0' : '255,0,0'},0.1)`,
        }}
      >
        <Icon name={icon} /> {title}
      </Box>
      {quirks.map((q) => {
        const chosen = selectedSet.has(q.name);
        const cost = q.cost > 0 ? `-${q.cost}` : `+${Math.abs(q.cost)}`;
        const costColor = q.cost > 0 ? 'bad' : 'good';

        let disabled = false;
        let buttonContent = chosen ? 'Remove' : 'Select';
        let buttonColor = chosen ? 'bad' : 'good';

        if (!chosen) {
          if (q.cost > 0 && !canAfford(q)) {
            disabled = true;
            buttonContent = 'Cannot Afford';
            buttonColor = 'average';
          }
        } else {
          const remainingQuirks = selected.filter((n) => n !== q.name);
          const remainingBalance = calculateBalance(remainingQuirks, allQuirks);
          if (q.cost < 0 && remainingBalance < 0) {
            disabled = true;
            buttonContent = 'Locked (Balance)';
            buttonColor = 'average';
          }
        }

        return (
          <Section
            key={q.name}
            title={q.name}
            mb={1}
            buttons={
              <Button
                {...{ color: buttonColor, content: buttonContent }}
                disabled={disabled}
                onClick={() => toggle(q)}
                fluid
              />
            }
          >
            <LabeledList>
              <LabeledList.Item label="Description">{q.desc}</LabeledList.Item>
              <LabeledList.Item label="Effect">
                <Box color={costColor} bold>
                  {cost}
                </Box>
              </LabeledList.Item>
            </LabeledList>
          </Section>
        );
      })}
    </>
  );

  return (
    <Section title="Quirks" fill>
      <Stack fill>
        <Stack.Item grow basis={500}>
          <Section title="Available Quirks" fill scrollable>
            <Stack vertical>
              {renderList(
                allQuirks.filter((q) => q.cost < 0),
                'Negative Quirks (Add Points)',
                'green',
                'minus-circle'
              )}
              {renderList(
                allQuirks.filter((q) => q.cost > 0),
                'Positive Quirks (Cost Points)',
                'bad',
                'plus-circle'
              )}
            </Stack>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Divider vertical />
        </Stack.Item>

        <Stack.Item basis={250}>
          <Stack vertical fill>
            <Section title="Balance">
              <Box bold color={balance >= 0 ? 'good' : 'bad'} fontSize="18px">
                {balance}
              </Box>
            </Section>
            <Section title="Selected Quirks" fill scrollable>
              {selected.length ? (
                selected.map((name) => {
                  const q = allQuirks.find((x) => x.name === name);
                  if (!q) return null;
                  const cost = q.cost > 0 ? `-${q.cost}` : `+${Math.abs(q.cost)}`;
                  const border = q.cost > 0 ? 'var(--color-bad)' : 'var(--color-good)';
                  return (
                    <Box key={name} mb={0.5} p={0.5} style={{ borderLeft: `3px solid ${border}` }}>
                      <Stack justify="space-between">
                        <Box bold>{name}</Box>
                        <Box>{cost}</Box>
                      </Stack>
                    </Box>
                  );
                })
              ) : (
                <Box italic>No quirks selected.</Box>
              )}
            </Section>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const AntagPreferencesTab = () => {
  const { act, data } = useBackend<CharacterData>();
  const { antag_preferences = {}, available_antags = [] } = data;

  const antagList =
    available_antags.length > 0
      ? available_antags
      : [
          {
            name: 'Traitor',
            key: 'traitor',
            description:
              'A secret agent sent to complete objectives by a faction called the Syndicate. Gets an Uplink which allows them to purchase gear and weapons for their mission.',
            icon: undefined,
          },
          {
            name: 'Vampire',
            key: 'vampire',
            description:
              'A bloodsucker with supernatural powers. Feeds on the blood of the crew to grow in strength and gain new abilities.',
            icon: undefined,
          },
          {
            name: 'Mindflayer',
            key: 'mindflayer',
            description:
              'An IPC host to a nanite swarm. Drains the mental energy of the crew to grow in strength and gain new abilities.',
            icon: undefined,
          },
          {
            name: 'Changeling',
            key: 'changeling',
            description:
              'A powerful, parasitic alien that has replaced your character. Can shapeshift to mimic other crew members.',
            icon: undefined,
          },
          {
            name: 'Cultist',
            key: 'cultist',
            description:
              'A founding member of a blood cult onstation seeking to summon their god. Works with other cultists to perform rituals and convert the crew.',
            icon: undefined,
          },
          {
            name: 'Wizard',
            key: 'wizard',
            description:
              'A devastatingly powerful spellcaster. Their goal is to cause as much chaos onstation as possible. Hunted by the entire crew.',
            icon: undefined,
          },
          {
            name: 'Revolutionary',
            key: 'revolutionary',
            description:
              'A crew member seeking to overthrow station command. Converts other crew to the revolutionary cause. This antag can only roll with admin intervention.',
            icon: undefined,
          },
        ];

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Antag Preferences">
          <Box mb={1} color="label">
            These settings determine whether you can be selected for various roles at roundstart. Antags not present
            here can be toggled in Global Antag Preferences.
          </Box>
          <Box
            style={{
              height: '400px',
              overflowY: 'auto',
              border: '1px solid #444',
              borderRadius: '4px',
              backgroundColor: 'rgba(0, 0, 0, 0.1)',
              padding: '8px',
            }}
          >
            <Stack vertical>
              {antagList.map((antag) => (
                <Stack.Item key={antag.key}>
                  <Box
                    style={{
                      border: '1px solid #444',
                      borderRadius: '4px',
                      padding: '8px',
                      marginBottom: '4px',
                      backgroundColor: 'rgba(0, 0, 0, 0.2)',
                    }}
                  >
                    <Stack>
                      <Stack.Item basis="80px">
                        <div
                          style={{
                            width: '64px',
                            height: '64px',
                            border: '1px solid #666',
                            borderRadius: '4px',
                            backgroundColor: '#222',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '10px',
                            color: '#888',
                          }}
                        >
                          {antag?.icon ? (
                            <img src={antag.icon} style={{ width: '100%', height: '100%' }} alt={antag.name} />
                          ) : (
                            'Preview'
                          )}
                        </div>
                      </Stack.Item>
                      <Stack.Item grow ml={2}>
                        <Stack vertical>
                          <Stack.Item>
                            <Box fontSize="16px" fontWeight="bold">
                              {antag.name}
                            </Box>
                          </Stack.Item>
                          <Stack.Item>
                            <Box fontSize="14px" color="label">
                              {antag.description}
                            </Box>
                          </Stack.Item>
                        </Stack>
                      </Stack.Item>
                      <Stack.Item>
                        <Stack vertical>
                          <Stack.Item>
                            <Box mb={1} textAlign="center" fontSize="12px" color="label">
                              Eligibility
                            </Box>
                          </Stack.Item>
                          <Stack.Item>
                            <Button.Checkbox
                              checked={antag_preferences[antag.key] || false}
                              onClick={() =>
                                act('toggle_antag_preference', {
                                  antag_type: antag.key,
                                })
                              }
                              content={antag_preferences[antag.key] ? 'Yes' : 'No'}
                              color={antag_preferences[antag.key] ? 'good' : 'average'}
                            />
                          </Stack.Item>
                        </Stack>
                      </Stack.Item>
                    </Stack>
                  </Box>
                </Stack.Item>
              ))}
            </Stack>
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const BackgroundTab = (props) => {
  const { act, data } = useBackend<CharacterData>();
  const {
    language,
    b_type,
    disabilities = 0,
    nanotrasen_relation,
    cyborg_brain_type,
    // AI/Cyborg settings
    ai_name,
    ai_core_display,
    ai_hologram,
    ai_hologram_color,
    cyborg_name,
    physique,
    height,
    flavor_text,
    med_record,
    sec_record,
    gen_record,
    available_languages = [],
    available_blood_types = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    available_disabilities = {},
    available_accents = {},
    available_nanotrasen_relations = ['Loyal', 'Supportive', 'Neutral', 'Skeptical', 'Opposed'],
    available_cyborg_brain_types = [],
    // AI/Cyborg options
    available_ai_core_displays = [],
    available_ai_holograms = [],
    available_physiques = [],
    available_heights = [],
  } = data;

  // Convert disabilities bitfield to readable format
  const getDisabilityList = (): DisabilityListItem[] => {
    const disabilityList: DisabilityListItem[] = [];
    for (const [key, disabilityData] of Object.entries(available_disabilities)) {
      const isSelected = (disabilities & disabilityData.flag) !== 0;
      disabilityList.push({
        key,
        name: disabilityData.name,
        flag: disabilityData.flag,
        selected: isSelected,
      });
    }
    return disabilityList;
  };

  // Convert accents bitfield to readable format
  const getAccentList = (): DisabilityListItem[] => {
    const accentList: DisabilityListItem[] = [];
    for (const [key, accentData] of Object.entries(available_accents)) {
      const isSelected = (disabilities & accentData.flag) !== 0;
      accentList.push({
        key,
        name: accentData.name,
        flag: accentData.flag,
        selected: isSelected,
      });
    }
    return accentList;
  };

  return (
    <Section title="Background" fill>
      <Stack fill vertical>
        <Stack.Item grow>
          <Stack fill>
            {/* Left column - narrower */}
            <Stack.Item basis="40%">
              <Stack fill vertical>
                <Stack.Item>
                  <Section title="Physical Characteristics">
                    <LabeledList>
                      <LabeledList.Item label="Physique">
                        <Dropdown
                          width="140px"
                          selected={physique || 'average'}
                          options={available_physiques || []}
                          onSelected={(value) => act('set_physique', { physique: value })}
                        />
                      </LabeledList.Item>
                      <LabeledList.Item label="Height">
                        <Dropdown
                          width="140px"
                          selected={height || 'average'}
                          options={available_heights || []}
                          onSelected={(value) => act('set_height', { height: value })}
                        />
                      </LabeledList.Item>
                    </LabeledList>
                  </Section>
                </Stack.Item>
                <Stack.Item>
                  <Section title="Language & Identity">
                    <LabeledList>
                      <LabeledList.Item label="Secondary Language">
                        <Dropdown
                          width="200px"
                          selected={language || 'None'}
                          options={['None'].concat(available_languages || [])}
                          onSelected={(value) => act('set_language', { language: value === 'None' ? null : value })}
                        />
                      </LabeledList.Item>
                      <LabeledList.Item label="Blood Type">
                        <Dropdown
                          width="100px"
                          selected={b_type || 'O+'}
                          options={available_blood_types || ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']}
                          onSelected={(value) => act('set_blood_type', { blood_type: value })}
                        />
                      </LabeledList.Item>
                      <LabeledList.Item label="Nanotrasen Relation">
                        <Dropdown
                          width="150px"
                          selected={nanotrasen_relation || 'Neutral'}
                          options={
                            available_nanotrasen_relations || ['Loyal', 'Supportive', 'Neutral', 'Skeptical', 'Opposed']
                          }
                          onSelected={(value) => act('set_nanotrasen_relation', { relation: value })}
                        />
                      </LabeledList.Item>
                    </LabeledList>
                  </Section>
                </Stack.Item>
                <Stack.Item>
                  <Section title="Accents">
                    <Stack vertical>
                      {getAccentList().map((accent) => (
                        <Stack.Item key={accent.key}>
                          <Button
                            fluid
                            selected={accent.selected}
                            onClick={() => act('toggle_disability', { disability: accent.flag })}
                            style={{
                              textAlign: 'left',
                              justifyContent: 'flex-start',
                            }}
                          >
                            {accent.name}
                          </Button>
                        </Stack.Item>
                      ))}
                      {getAccentList().length === 0 && (
                        <Box color="label" italic>
                          No accents available for this species.
                        </Box>
                      )}
                    </Stack>
                  </Section>
                </Stack.Item>
                <Stack.Item>
                  <Section title="Disabilities">
                    <Stack vertical>
                      {getDisabilityList().map((disability) => (
                        <Stack.Item key={disability.key}>
                          <Button
                            fluid
                            selected={disability.selected}
                            onClick={() => act('toggle_disability', { disability: disability.flag })}
                            style={{
                              textAlign: 'left',
                              justifyContent: 'flex-start',
                            }}
                          >
                            {disability.name}
                          </Button>
                        </Stack.Item>
                      ))}
                      {getDisabilityList().length === 0 && (
                        <Box color="label" italic>
                          No disabilities available for this species.
                        </Box>
                      )}
                    </Stack>
                  </Section>
                </Stack.Item>
                <Stack.Item grow></Stack.Item>
              </Stack>
            </Stack.Item>

            {/* Right column - wider */}
            <Stack.Item basis="60%" ml={2}>
              {/* AI Settings */}
              <Section title="AI Settings">
                <LabeledList>
                  <LabeledList.Item label="AI Name">
                    <Input
                      width="200px"
                      value={ai_name || ''}
                      placeholder="Default AI Name"
                      onChange={(value) => act('set_ai_name', { name: value })}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Core Display">
                    <Dropdown
                      width="200px"
                      selected={ai_core_display || 'Blue'}
                      options={
                        available_ai_core_displays?.length > 0 ? available_ai_core_displays : ['Blue', 'Smiley']
                      }
                      onSelected={(value) => act('set_ai_core_display', { display: value })}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Hologram">
                    <Dropdown
                      width="200px"
                      selected={ai_hologram || 'default'}
                      options={
                        available_ai_holograms?.length > 0 ? available_ai_holograms : ['default', 'floating face']
                      }
                      onSelected={(value) => act('set_ai_hologram', { hologram: value })}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Hologram Color">
                    <ColorBox
                      color={ai_hologram_color || '#ffffff'}
                      onClick={() => act('set_ai_hologram_color')}
                    />
                  </LabeledList.Item>
                </LabeledList>
                <Box mt={2} color="label" fontSize="12px">
                  These settings apply when playing as an AI. The core display affects your monitor appearance, and the hologram is your projected form.
                </Box>
                {/* Debug buttons for testing AI/cyborg jobs */}
                <Box mt={2}>
                  <Button onClick={() => act('set_ai_job_test')} content="Test AI Job" />
                  <Button ml={1} onClick={() => act('set_cyborg_job_test')} content="Test Cyborg Job" />
                  <Button ml={1} onClick={() => act('clear_job_test')} content="Clear Jobs" />
                </Box>
              </Section>

              {/* Cyborg Settings */}
              <Section title="Cyborg Settings" mt={2}>
                <LabeledList>
                  <LabeledList.Item label="Cyborg Name">
                    <Input
                      width="200px"
                      value={cyborg_name || ''}
                      placeholder="Default Cyborg Name"
                      onChange={(value) => act('set_cyborg_name', { name: value })}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Brain Type">
                    <Dropdown
                      width="200px"
                      selected={cyborg_brain_type || 'Posibrain'}
                      options={
                        available_cyborg_brain_types?.length > 0 ? available_cyborg_brain_types : ['Posibrain']
                      }
                      onSelected={(value) => act('set_cyborg_brain_type', { brain_type: value })}
                    />
                  </LabeledList.Item>
                </LabeledList>
                <Box mt={2} color="label" fontSize="12px">
                  These settings apply when playing as a cyborg. The brain type determines your processing unit, and the name is your designation.
                </Box>
              </Section>

              <Section title="Character Records" fill mt={2}>
                <Stack fill vertical>
                  {/* Flavor Text */}
                  <Stack.Item>
                    <Stack>
                      <Stack.Item grow>
                        <Button
                          fluid
                          icon="file-text"
                          content={flavor_text ? 'Edit Flavor Text' : 'Set Flavor Text'}
                          onClick={() => act('set_flavor_text_dialog')}
                        />
                      </Stack.Item>
                      {flavor_text && (
                        <Stack.Item>
                          <Button.Confirm
                            icon="trash"
                            tooltip="Clear flavor text"
                            onClick={() => act('clear_flavor_text')}
                          />
                        </Stack.Item>
                      )}
                    </Stack>
                    {flavor_text && (
                      <Box
                        mt={1}
                        p={2}
                        backgroundColor="rgba(255, 255, 255, 0.05)"
                        style={{
                          border: '1px solid #555',
                          borderRadius: '4px',
                          fontSize: '12px',
                          lineHeight: '1.4',
                          maxHeight: '60px',
                          overflowY: 'auto',
                        }}
                      >
                        {flavor_text}
                      </Box>
                    )}
                  </Stack.Item>

                  {/* Medical Record */}
                  <Stack.Item>
                    <Stack>
                      <Stack.Item grow>
                        <Button
                          fluid
                          icon="notes-medical"
                          content={med_record ? 'Edit Medical Record' : 'Set Medical Record'}
                          onClick={() => act('set_medical_record')}
                        />
                      </Stack.Item>
                      {med_record && (
                        <Stack.Item>
                          <Button.Confirm
                            icon="trash"
                            tooltip="Clear medical record"
                            onClick={() => act('clear_medical_record')}
                          />
                        </Stack.Item>
                      )}
                    </Stack>
                    {med_record && (
                      <Box
                        mt={1}
                        p={2}
                        backgroundColor="rgba(255, 255, 255, 0.05)"
                        style={{
                          border: '1px solid #555',
                          borderRadius: '4px',
                          fontSize: '12px',
                          lineHeight: '1.4',
                          maxHeight: '60px',
                          overflowY: 'auto',
                        }}
                      >
                        {med_record}
                      </Box>
                    )}
                  </Stack.Item>

                  {/* Security Record */}
                  <Stack.Item>
                    <Stack>
                      <Stack.Item grow>
                        <Button
                          fluid
                          icon="shield-alt"
                          content={sec_record ? 'Edit Security Record' : 'Set Security Record'}
                          onClick={() => act('set_security_record')}
                        />
                      </Stack.Item>
                      {sec_record && (
                        <Stack.Item>
                          <Button.Confirm
                            icon="trash"
                            tooltip="Clear security record"
                            onClick={() => act('clear_security_record')}
                          />
                        </Stack.Item>
                      )}
                    </Stack>
                    {sec_record && (
                      <Box
                        mt={1}
                        p={2}
                        backgroundColor="rgba(255, 255, 255, 0.05)"
                        style={{
                          border: '1px solid #555',
                          borderRadius: '4px',
                          fontSize: '12px',
                          lineHeight: '1.4',
                          maxHeight: '60px',
                          overflowY: 'auto',
                        }}
                      >
                        {sec_record}
                      </Box>
                    )}
                  </Stack.Item>

                  {/* Employment Record */}
                  <Stack.Item>
                    <Stack>
                      <Stack.Item grow>
                        <Button
                          fluid
                          icon="briefcase"
                          content={gen_record ? 'Edit Employment Record' : 'Set Employment Record'}
                          onClick={() => act('set_employment_record')}
                        />
                      </Stack.Item>
                      {gen_record && (
                        <Stack.Item>
                          <Button.Confirm
                            icon="trash"
                            tooltip="Clear employment record"
                            onClick={() => act('clear_employment_record')}
                          />
                        </Stack.Item>
                      )}
                    </Stack>
                    {gen_record && (
                      <Box
                        mt={1}
                        p={2}
                        backgroundColor="rgba(255, 255, 255, 0.05)"
                        style={{
                          border: '1px solid #555',
                          borderRadius: '4px',
                          fontSize: '12px',
                          lineHeight: '1.4',
                          maxHeight: '60px',
                          overflowY: 'auto',
                        }}
                      >
                        {gen_record}
                      </Box>
                    )}
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};
