/**
 * Species selection component for the character creator
 * Backend sibling: code/modules/client/preference/character_creator/species_selection.dm
 */

import { Box } from 'tgui-core/components';

import { useBackend } from '../../backend';

// Helper function to filter HTML tags from description text
const filterHtmlTags = (text: string): string => {
  if (!text) return '';
  return text
    .replace(/<br\s*\/?>/gi, ' ')
    .replace(/<[^>]*>/g, '')
    .trim();
};

interface SpeciesInfo {
  name: string;
  description: string;
  flesh_color: string;
  icon: string;
}

interface SpeciesSelectionData {
  selected_species: string;
  available_species: Record<string, SpeciesInfo>;
}

interface SpeciesSelectionProps {
  data: SpeciesSelectionData;
}

export const SpeciesSelection = (props: SpeciesSelectionProps) => {
  const { act } = useBackend();
  const { data } = props;
  const { selected_species, available_species } = data;

  const speciesEntries = Object.entries(available_species);

  return (
    <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', height: '100%' }}>
      {speciesEntries.map(([speciesKey, speciesInfo]) => (
        <Box
          key={speciesKey}
          style={{
            flex: '1 0 calc(50% - 4px)',
            minWidth: '300px',
            border: selected_species === speciesKey ? '2px solid #4a9eff' : '1px solid #404040',
            borderRadius: '4px',
            padding: '12px',
            backgroundColor: selected_species === speciesKey ? 'rgba(74, 158, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
            cursor: 'pointer',
            position: 'relative',
            minHeight: '120px',
            transition: 'all 0.2s ease',
            overflow: 'hidden',
          }}
          onClick={() =>
            act('set_species', {
              species: speciesKey,
            })
          }
        >
          {/* Species preview image in background (bottom right) */}
          <Box
            style={{
              position: 'absolute',
              bottom: '8px',
              right: '8px',
              width: '80px',
              height: '80px',
              backgroundImage: `url('species_preview_${speciesKey}.png')`,
              backgroundSize: 'contain',
              backgroundRepeat: 'no-repeat',
              backgroundPosition: 'center',
              opacity: 0.3,
              zIndex: 1,
            }}
          />

          {/* Content container */}
          <Box style={{ position: 'relative', zIndex: 2, height: '100%', display: 'flex', flexDirection: 'column' }}>
            {/* Species Name - top left, larger */}
            <Box fontSize="15px" fontWeight="bold" mb={2} style={{ color: speciesInfo.flesh_color || '#fff' }}>
              {speciesInfo.name}
            </Box>

            {/* Species Description - fills remaining space */}
            <Box
              fontSize="11px"
              color="label"
              style={{
                lineHeight: '1.4',
                flex: 1,
                overflow: 'hidden',
                paddingRight: '90px', // Leave space for background image
              }}
            >
              {filterHtmlTags(speciesInfo.description) || 'No description available.'}
            </Box>
          </Box>
        </Box>
      ))}
    </Box>
  );
};
