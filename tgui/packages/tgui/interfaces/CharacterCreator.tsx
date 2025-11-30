import { useState } from 'react';
import * as React from 'react';
import { Box, Button, Dropdown, Input, LabeledList, Section, Stack, Tabs } from 'tgui-core/components';
import { createSearch } from 'tgui-core/string';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface CharacterCreatorData {
  available_prosthetics?: { [key: string]: any[] };
  prosthetic_states?: { [key: string]: string };
  is_machine_species?: boolean;
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
  available_hair_styles: HairStyle[];
  available_facial_hair_styles: HairStyle[];
  available_hair_gradients: HairStyle[];
  available_wings?: HairStyle[];
  available_underwear: HairStyle[];
  available_undershirt: HairStyle[];
  available_socks: HairStyle[];
  available_backpack_types: BackpackType[];
  available_genders: string[];
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

enum Tab {
  Character = 0,
  Job = 1,
}

enum AppearanceTab {
  General = 0,
  Hair = 1,
  FacialHair = 2,
  Wings = 3,
  Clothing = 4,
  Prosthetics = 5,
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

// Main character creator component
export const CharacterCreator = (props) => {
  const { act, data } = useBackend<CharacterData>();
  const [selectedTab, setSelectedTab] = useState<Tab>(Tab.Character);

  return (
    <Window width={900} height={910} title="Character Creator (New)">
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                key="character"
                selected={selectedTab === Tab.Character}
                onClick={() => setSelectedTab(Tab.Character)}
              >
                Character & Appearance
              </Tabs.Tab>
              <Tabs.Tab key="job" selected={selectedTab === Tab.Job} onClick={() => setSelectedTab(Tab.Job)}>
                Job Preferences
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow style={{ paddingBottom: '80px', overflowY: 'auto' }}>
            {getTabContent(selectedTab)}
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

const getTabContent = (tab: Tab) => {
  switch (tab) {
    case Tab.Character:
      return <CharacterTab />;
    case Tab.Job:
      return <JobTab />;
    default:
      return <CharacterTab />;
  }
};

const CharacterTab = (props) => {
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
    flavor_text,
    available_species,
    available_genders,
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

  const [selectedAppearanceTab, setSelectedAppearanceTab] = useState<AppearanceTab>(AppearanceTab.General);
  const [previousSpecies, setPreviousSpecies] = useState<string>('');

  // When we change species we might need to back out to General if the current tab is now invalid
  React.useEffect(() => {
    if (previousSpecies !== '' && previousSpecies !== species) {
      const isCurrentTabValid =
        selectedAppearanceTab === AppearanceTab.General ||
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
      <Stack.Item>
        <Section title="Basic Information">
          <Stack>
            <Stack.Item basis="33%">
              <LabeledList>
                <LabeledList.Item label="Name">
                  <Stack>
                    <Stack.Item grow>
                      <Input
                        fluid
                        value={real_name}
                        onChange={(value) =>
                          act('set_name', {
                            name: value,
                          })
                        }
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button icon="dice" tooltip="Random Name" onClick={() => act('random_name')} />
                    </Stack.Item>
                  </Stack>
                </LabeledList.Item>
                <LabeledList.Item label="Age">
                  <Input
                    width="80px"
                    value={age.toString()}
                    onChange={(value) =>
                      act('set_age', {
                        age: parseInt(value) || 18,
                      })
                    }
                  />
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item basis="33%">
              <LabeledList>
                <LabeledList.Item label="Species">
                  <Dropdown
                    width="150px"
                    selected={species}
                    options={available_species}
                    onSelected={(value) =>
                      act('set_species', {
                        species: value,
                      })
                    }
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Gender">
                  <Stack>
                    {available_genders.map((genderOption) => (
                      <Stack.Item key={genderOption}>
                        <Button
                          selected={gender === genderOption}
                          onClick={() =>
                            act('set_gender', {
                              gender: genderOption,
                            })
                          }
                        >
                          {genderOption}
                        </Button>
                      </Stack.Item>
                    ))}
                  </Stack>
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
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
          </Stack>
        </Section>
      </Stack.Item>

      {/* Character preview - front facing and side facing */}
      <Stack.Item>
        <Box height="140px" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {has_preview ? (
            <Stack>
              <Stack.Item grow />
              <Stack.Item>
                <img
                  src={`char_preview_front_${preview_timestamp}.png`}
                  style={{
                    width: '128px',
                    height: '128px',
                    imageRendering: 'pixelated',
                    marginRight: '8px',
                  }}
                  alt="Character Front View"
                />
              </Stack.Item>
              <Stack.Item>
                <img
                  src={`char_preview_side_${preview_timestamp}.png`}
                  style={{
                    width: '128px',
                    height: '128px',
                    imageRendering: 'pixelated',
                    marginLeft: '8px',
                  }}
                  alt="Character Side View"
                />
              </Stack.Item>
              <Stack.Item grow />
            </Stack>
          ) : (
            <Box textAlign="center" color="label" p={2}>
              Preview will be available once the server finishes loading...
            </Box>
          )}
        </Box>
      </Stack.Item>

      {/* Appearance section, which has its own sub-tabs which are dynamically shown and hidden */}
      <Stack.Item grow>
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
                act,
              })}
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const getAppearanceTabContent = (tab: AppearanceTab, props: any) => {
  switch (tab) {
    case AppearanceTab.General:
      return <GeneralSubTab {...props} />;
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

const GeneralSubTab = (props) => {
  const { e_colour, s_colour, act } = props;
  return (
    <Stack fill vertical>
      <Stack.Item grow>
        <Stack fill>
          <Stack.Item basis="50%">
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
            </LabeledList>
          </Stack.Item>
          <Stack.Item basis="50%">
            <LabeledList>
              <LabeledList.Item label="Skin Color">
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
