/**
 * Species selection component for the character creator
 * Backend sibling: code/modules/client/preference/character_creator/species_selection.dm
 */

import { useEffect, useState } from 'react';
import { Box } from 'tgui-core/components';

import { useBackend } from '../../backend';

// Helper function to filter HTML tags from description text
const filterHtmlTags = (text: string): string => {
  if (!text) return '';
  return text
    .replace(/<br\s*\/?>/gi, '\n') // Convert HTML breaks to actual linebreaks
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
  has_character_preview?: boolean;
  preview_timestamp?: number;
}

interface SpeciesSelectionProps {
  data: SpeciesSelectionData;
}

// Double-buffered image component to prevent flickering for character preview
const DoubleBufferedImage = ({ src, alt, style }: { src: string; alt: string; style: React.CSSProperties }) => {
  const [currentSrc, setCurrentSrc] = useState(src);
  const [previousSrc, setPreviousSrc] = useState<string | null>(null);
  const [showPrevious, setShowPrevious] = useState(false);

  useEffect(() => {
    if (src !== currentSrc) {
      setPreviousSrc(currentSrc);
      setShowPrevious(true);

      // Preload new image
      const img = new Image();
      img.onload = () => {
        setCurrentSrc(src);
        // Hide previous image immediately after new one loads
        setShowPrevious(false);
        setPreviousSrc(null);
      };
      img.src = src;
    }
  }, [src, currentSrc]);

  return (
    <div style={{ position: 'relative', ...style }}>
      {/* Previous image */}
      {showPrevious && previousSrc && (
        <img
          src={previousSrc}
          alt={alt}
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            imageRendering: 'pixelated',
          }}
        />
      )}
      {/* Current image */}
      <img
        src={currentSrc}
        alt={alt}
        style={{
          width: '100%',
          height: '100%',
          imageRendering: 'pixelated',
        }}
      />
    </div>
  );
};

export const SpeciesSelection = (props: SpeciesSelectionProps) => {
  const { act } = useBackend();
  const { data } = props;
  const { selected_species, available_species, has_character_preview, preview_timestamp } = data;

  const speciesEntries = Object.entries(available_species);
  const selectedSpeciesInfo = available_species[selected_species];

  return (
    <Box style={{ display: 'flex', height: '100%' }}>
      {/* Left side: Species list */}
      <Box
        style={{
          flex: '0 0 20%', // Reduced from 40% to 20%
          height: '400px', // Fixed height
          maxHeight: '400px',
          overflowY: 'auto',
          overflowX: 'hidden',
          paddingRight: '8px',
          border: '1px solid #404040',
          borderRadius: '4px',
          backgroundColor: 'rgba(0, 0, 0, 0.1)',
        }}
      >
        {speciesEntries.map(([speciesKey, speciesInfo]) => (
          <Box
            key={speciesKey}
            style={{
              border: selected_species === speciesKey ? '2px solid #4a9eff' : '1px solid #404040',
              borderRadius: '4px',
              padding: '8px',
              marginBottom: '4px',
              backgroundColor: selected_species === speciesKey ? 'rgba(74, 158, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
              cursor: 'pointer',
              transition: 'all 0.2s ease',
            }}
            onClick={() =>
              act('set_species', {
                species: speciesKey,
              })
            }
          >
            <Box fontSize="13px" fontWeight="bold" mb={1} style={{ color: speciesInfo.flesh_color || '#fff' }}>
              {speciesInfo.name}
            </Box>
          </Box>
        ))}
      </Box>

      {/* Right side: Selected species details and character preview */}
      <Box style={{ flex: '1 1 80%', height: '100%', paddingLeft: '16px' }}>
        {selectedSpeciesInfo ? (
          <Box style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
            {/* Species name and description with front sprite on the right */}
            <Box style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '16px' }}>
              {/* Left side: Name and description */}
              <Box
                style={{
                  flex: 1,
                  paddingRight: '16px',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'center',
                }}
              >
                <Box
                  fontSize="18px"
                  fontWeight="bold"
                  mb={2}
                  style={{ color: selectedSpeciesInfo.flesh_color || '#fff' }}
                >
                  {selectedSpeciesInfo.name}
                </Box>
                <Box
                  fontSize="13px"
                  color="label"
                  style={{
                    lineHeight: '1.4',
                    overflow: 'hidden',
                    whiteSpace: 'pre-line', // This allows \n linebreaks to display properly
                  }}
                >
                  {filterHtmlTags(selectedSpeciesInfo.description) || 'No description available.'}
                </Box>
              </Box>

              {/* Right side: Front sprite only */}
              <Box style={{ flex: '0 0 256px', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                {has_character_preview && preview_timestamp ? (
                  <DoubleBufferedImage
                    src={`species_char_preview_front_${preview_timestamp}.png`}
                    alt="Character Front View"
                    style={{
                      width: '256px', // 2x size
                      height: '256px', // 2x size
                    }}
                  />
                ) : (
                  <Box
                    textAlign="center"
                    color="label"
                    p={2}
                    style={{
                      width: '256px',
                      height: '256px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    Preview loading...
                  </Box>
                )}
              </Box>
            </Box>
          </Box>
        ) : (
          <Box style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
            <Box textAlign="center" color="label" p={2}>
              Select a species to see details and preview.
            </Box>
          </Box>
        )}
      </Box>
    </Box>
  );
};
