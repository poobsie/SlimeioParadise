import { useState } from 'react';
import { Box, Button, Input, Section, Stack, Tabs } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type HairStyle = {
  name: string;
  icon_state: string;
  icon: string;
};

type HairStylistData = {
  target_name: string;
  has_preview: BooleanLike;
  preview_timestamp: number;
  available_hair_styles: HairStyle[];
  available_facial_hair_styles: HairStyle[];
  selected_hair_style: string;
  selected_facial_hair_style: string;
  can_style_hair: BooleanLike;
  can_style_facial_hair: BooleanLike;
};

export const HairStylist = () => {
  return (
    <Window width={900} height={700} title="Professional Hair Stylist">
      <Window.Content>
        <HairStylistContent />
      </Window.Content>
    </Window>
  );
};

const HairStylistContent = () => {
  const { act, data } = useBackend<HairStylistData>();
  const {
    target_name,
    available_hair_styles = [],
    available_facial_hair_styles = [],
    selected_hair_style,
    selected_facial_hair_style,
    can_style_hair,
    can_style_facial_hair,
  } = data;

  const [activeTab, setActiveTab] = useState(can_style_hair ? 0 : 1);
  const [searchHairText, setSearchHairText] = useState('');
  const [searchFacialText, setSearchFacialText] = useState('');

  // Filter hair styles based on search
  const filteredHairStyles = available_hair_styles.filter((style) =>
    style.name.toLowerCase().includes(searchHairText.toLowerCase())
  );

  // Filter facial hair styles based on search
  const filteredFacialHairStyles = available_facial_hair_styles.filter((style) =>
    style.name.toLowerCase().includes(searchFacialText.toLowerCase())
  );

  const tabs: Array<{ key: number; title: string; content: React.JSX.Element }> = [];
  if (can_style_hair) {
    tabs.push({
      key: 0,
      title: 'Hair Styles',
      content: (
        <HairStyleGrid
          styles={filteredHairStyles}
          selectedStyle={selected_hair_style}
          onStyleSelect={(style) => act('set_hair_style', { style })}
          searchText={searchHairText}
          onSearchChange={setSearchHairText}
          searchPlaceholder="Search hair styles..."
        />
      ),
    });
  }
  
  if (can_style_facial_hair) {
    tabs.push({
      key: 1,
      title: 'Facial Hair Styles',
      content: (
        <HairStyleGrid
          styles={filteredFacialHairStyles}
          selectedStyle={selected_facial_hair_style}
          onStyleSelect={(style) => act('set_facial_hair_style', { style })}
          searchText={searchFacialText}
          onSearchChange={setSearchFacialText}
          searchPlaceholder="Search facial hair styles..."
        />
      ),
    });
  }

  return (
    <Stack fill vertical>
      {/* Header Section */}
      <Stack.Item>
        <Section title={`Styling: ${target_name}`}>
          <Stack>
            <Stack.Item grow>
              <Box textAlign="center" fontSize="16px" p={1}>
                Currently Selected: {selected_hair_style || "None"} | {selected_facial_hair_style || "None"}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="check"
                content="Apply Changes"
                color="good"
                onClick={() => act('apply_styles')}
                disabled={!selected_hair_style && !selected_facial_hair_style}
              />
            </Stack.Item>
            <Stack.Item>
              <Button icon="times" content="Cancel" color="bad" onClick={() => act('close')} />
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      {/* Style Selection Section */}
      <Stack.Item grow>
        <Section fill>
          <Tabs fluid>
            {tabs.map((tab) => (
              <Tabs.Tab
                key={tab.key}
                selected={activeTab === tab.key}
                onClick={() => setActiveTab(tab.key)}
              >
                {tab.title}
              </Tabs.Tab>
            ))}
          </Tabs>
          {tabs[activeTab]?.content}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const HairStyleGrid = ({ 
  styles, 
  selectedStyle, 
  onStyleSelect, 
  searchText, 
  onSearchChange, 
  searchPlaceholder 
}: {
  styles: HairStyle[];
  selectedStyle: string;
  onStyleSelect: (style: string) => void;
  searchText: string;
  onSearchChange: (text: string) => void;
  searchPlaceholder: string;
}) => {
  return (
    <Stack vertical fill>
      <Stack.Item>
        <Input
          fluid
          placeholder={searchPlaceholder}
          value={searchText}
          onChange={(value) => onSearchChange(value)}
          mb={2}
        />
      </Stack.Item>
      <Stack.Item grow>
        <Box
          height="500px"
          overflowY="auto"
          style={{
            border: '1px solid #666',
            borderRadius: '4px',
            padding: '8px',
            backgroundColor: 'rgba(32, 32, 32, 0.5)',
          }}
        >
          {styles.length === 0 ? (
            <Box textAlign="center" color="label" p={4}>
              No styles found matching your search.
            </Box>
          ) : (
            styles.map((style) => {
              const isSelected = style.name === selectedStyle;
              return (
                <Box
                  key={style.name}
                  style={{
                    display: 'inline-flex',
                    flexDirection: 'column',
                    justifyContent: 'space-between',
                    margin: '4px',
                    padding: '6px',
                    border: isSelected ? '2px solid #4a9eff' : '1px solid #666',
                    borderRadius: '4px',
                    backgroundColor: isSelected ? 'rgba(74, 158, 255, 0.2)' : 'rgba(64, 64, 64, 0.3)',
                    textAlign: 'center',
                    width: '90px',
                    height: '110px',
                    transition: 'all 0.2s ease',
                    overflow: 'hidden',
                    cursor: 'pointer',
                  }}
                  onClick={() => onStyleSelect(style.name)}
                >
                  <Box
                    style={{
                      width: '76px',
                      height: '76px',
                      border: '1px solid rgba(255,255,255,0.1)',
                      borderRadius: '3px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      backgroundColor: 'rgba(0,0,0,0.2)',
                      margin: '0 auto 4px auto',
                    }}
                  >
                    <img
                      src={style.icon}
                      alt={style.name}
                      style={{
                        width: '64px',
                        height: '64px',
                        imageRendering: 'pixelated',
                        transform: 'scale(2)',
                      }}
                      onError={(e) => {
                        console.log(`Failed to load style image: ${style.icon}`);
                        // Hide broken image
                        e.currentTarget.style.display = 'none';
                      }}
                    />
                  </Box>
                  <Box
                    style={{
                      fontSize: '10px',
                      fontFamily: 'Verdana, Arial, sans-serif',
                      fontWeight: isSelected ? 'bold' : 'normal',
                      color: isSelected ? '#ffffff' : '#cccccc',
                      textShadow: '1px 1px 2px rgba(0,0,0,0.8)',
                      height: '20px',
                      lineHeight: '10px',
                      overflow: 'hidden',
                      textAlign: 'center',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      wordBreak: 'break-word',
                    }}
                  >
                    {style.name}
                  </Box>
                </Box>
              );
            })
          )}
        </Box>
      </Stack.Item>
    </Stack>
  );
};
