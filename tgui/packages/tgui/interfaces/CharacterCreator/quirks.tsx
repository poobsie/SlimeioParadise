/**
 * Quirks selection component for the character creator
 * Backend sibling: code/modules/client/preference/character_creator_tgui.dm
 */

import { useEffect, useState } from 'react';
import { Box, Button, Divider, Icon, Section, Stack } from 'tgui-core/components';
import { useBackend } from '../../backend';

// Add CSS for hover effects
const quirkStyles = `
  .quirk-line:not(.disabled):hover {
    background-color: rgba(128, 128, 128, 0.2) !important;
  }
  .quirk-line.selected:not(.disabled):hover {
    background-color: rgba(0, 150, 255, 0.3) !important;
  }
`;

// Inject styles
if (typeof document !== 'undefined') {
  const styleElement = document.createElement('style');
  styleElement.textContent = quirkStyles;
  document.head.appendChild(styleElement);
}

interface Quirk {
  name: string;
  desc: string;
  cost: number;
  path: string;
  species_whitelist?: string[];
  species_blacklist?: string[];
  machine_only?: boolean;
}

interface CharacterCreatorData {
  selected_quirks?: string[];
  quirk_balance?: number;
  all_quirks?: Quirk[];
  species?: string;
  is_machine_species?: boolean;
}

const calculateBalance = (selected: string[], allQuirks: Quirk[]) => {
  return selected.reduce((sum, quirkName) => {
    const quirk = allQuirks.find((q) => q.name === quirkName);
    return quirk ? sum - quirk.cost : sum;
  }, 0);
};

export const QuirksTab = (props) => {
  const { act, data } = useBackend<CharacterCreatorData>();

  const selectedQuirks = data.selected_quirks || [];
  const allQuirks = data.all_quirks || [];
  const species = data.species || 'human';
  const isMachineSpecies = data.is_machine_species || false;
  const [selected, setSelected] = useState(selectedQuirks);

  useEffect(() => setSelected(selectedQuirks), [selectedQuirks]);

  // Filter quirks based on species requirements
  const isQuirkAvailable = (quirk: Quirk) => {
    // Debug logging
    if (quirk.machine_only) {
      console.log(`Machine quirk ${quirk.name}: species=${species}, isMachine=${isMachineSpecies}`);
    }
    
    // Check machine-only restriction
    if (quirk.machine_only && !isMachineSpecies) {
      return false;
    }
    
    // Check species whitelist (if present, species must be in the list)
    if (quirk.species_whitelist && quirk.species_whitelist.length > 0) {
      if (!quirk.species_whitelist.includes(species)) {
        return false;
      }
    }
    
    // Check species blacklist (if present, species must NOT be in the list)
    if (quirk.species_blacklist && quirk.species_blacklist.length > 0) {
      if (quirk.species_blacklist.includes(species)) {
        return false;
      }
    }
    
    return true;
  };

  const availableQuirks = allQuirks.filter(isQuirkAvailable);

  const selectedSet = new Set(selected);

  // Calculate the current balance using all quirks (including unavailable ones for current selections)
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

  const renderQuirkLine = (q: Quirk) => {
    const chosen = selectedSet.has(q.name);
    const cost = q.cost > 0 ? `-${q.cost}` : `+${Math.abs(q.cost)}`;
    const costColor = q.cost > 0 ? '#ff4444' : '#44ff44';
    const icon = q.cost > 0 ? 'plus-circle' : 'minus-circle';

    let disabled = false;
    if (!chosen) {
      if (q.cost > 0 && !canAfford(q)) {
        disabled = true;
      }
    } else {
      const remainingQuirks = selected.filter((n) => n !== q.name);
      const remainingBalance = calculateBalance(remainingQuirks, allQuirks);
      if (q.cost < 0 && remainingBalance < 0) {
        disabled = true;
      }
    }

    return (
      <Button
        style={{
          padding: '4px 8px',
          margin: '1px 0',
          backgroundColor: chosen ? 'rgba(0, 150, 255, 0.2)' : 'rgba(128, 128, 128, 0.1)',
          border: chosen ? '1px solid #0096ff' : '1px solid transparent',
          borderRadius: '2px',
          cursor: disabled ? 'not-allowed' : 'pointer',
          opacity: disabled ? 0.5 : 1,
          transition: 'all 0.2s ease',
          width: '100%',
          textAlign: 'left',
        }}
        className={`quirk-line ${chosen ? 'selected' : ''} ${disabled ? 'disabled' : ''}`}
        onClick={() => !disabled && toggle(q)}
        tooltip={q.desc}
        tooltipPosition="right"
      >
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
          <div style={{ display: 'flex', alignItems: 'center', flex: 1, minWidth: 0 }}>
            <Icon 
              name={icon} 
              style={{ 
                marginRight: '8px', 
                color: costColor,
                fontSize: '14px',
                flexShrink: 0
              }} 
            />
            <span style={{ 
              fontSize: '13px', 
              fontWeight: chosen ? 'bold' : 'normal',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap'
            }}>
              {q.name}
            </span>
          </div>
          <span 
            style={{ 
              fontSize: '13px', 
              fontWeight: 'bold',
              color: costColor,
              flexShrink: 0,
              marginLeft: '8px'
            }}
          >
            {cost}
          </span>
        </div>
          {cost}
        </span>
      </Button>
    );
  };

  // Separate available quirks into positive and negative
  const negativeQuirks = availableQuirks.filter((q) => q.cost < 0);
  const positiveQuirks = availableQuirks.filter((q) => q.cost > 0);

  return (
    <Section title="Quirks" fill>
      <Stack fill>
        <Stack.Item grow basis={500}>
          <Stack fill>
            {/* Left column - Negative Quirks */}
            <Stack.Item basis="50%">
              <Section title="Negative Quirks (+Points)" fill scrollable>
                <Stack vertical>
                  {negativeQuirks.map(renderQuirkLine)}
                </Stack>
              </Section>
            </Stack.Item>
            
            {/* Right column - Positive Quirks */}
            <Stack.Item basis="50%" ml={1}>
              <Section title="Positive Quirks (-Points)" fill scrollable>
                <Stack vertical>
                  {positiveQuirks.map(renderQuirkLine)}
                </Stack>
              </Section>
            </Stack.Item>
          </Stack>
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