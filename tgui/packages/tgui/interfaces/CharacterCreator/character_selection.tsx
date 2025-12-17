/**
 * Character selection component for the character creator
 * Backend sibling: code/modules/client/preference/character_creator/character_preview.dm
 */

import { useBackend } from '../../backend';
import { useState, useEffect } from 'react';

interface CharacterSave {
  slot: number;
  name: string;
  species: string;
  is_active: boolean;
  valid_save: boolean;
  preview_headshot?: string;
}

interface CharacterSelectionProps {
  character_saves: CharacterSave[];
}

// Double-buffered headshot component to prevent flickering
const DoubleBufferedHeadshot = ({ character, style }: { character: CharacterSave; style: React.CSSProperties }) => {
  const [currentImage, setCurrentImage] = useState(character.preview_headshot);
  const [previousImage, setPreviousImage] = useState<string | null>(null);
  const [showPrevious, setShowPrevious] = useState(false);

  useEffect(() => {
    if (character.preview_headshot !== currentImage) {
      setPreviousImage(currentImage || null);
      setShowPrevious(!!currentImage);

      if (character.preview_headshot) {
        // Preload new image
        const img = new Image();
        img.onload = () => {
          setCurrentImage(character.preview_headshot);
          // Hide previous image after new one loads
          setTimeout(() => {
            setShowPrevious(false);
            setPreviousImage(null);
          }, 50); // Brief overlap to prevent flickering
        };
        img.src = character.preview_headshot;
      } else {
        setCurrentImage(character.preview_headshot);
        setShowPrevious(false);
        setPreviousImage(null);
      }
    }
  }, [character.preview_headshot, currentImage]);

  return (
    <div style={style}>
      {/* Previous image */}
      {showPrevious && previousImage && (
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            backgroundImage: `url("${previousImage}")`,
            backgroundSize: '128px auto',
            backgroundRepeat: 'no-repeat',
            backgroundPosition: 'calc(50% + 2px) calc(0% - 2px)',
            imageRendering: 'pixelated',
          }}
        />
      )}
      {/* Current image or slot number */}
      {currentImage ? (
        <div
          style={{
            width: '100%',
            height: '100%',
            backgroundImage: `url("${currentImage}")`,
            backgroundSize: '128px auto',
            backgroundRepeat: 'no-repeat',
            backgroundPosition: 'calc(50% + 2px) calc(0% - 2px)',
            imageRendering: 'pixelated',
          }}
        />
      ) : (
        <div
          style={{
            width: '100%',
            height: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#666',
            fontSize: '10px',
          }}
        >
          {character.slot}
        </div>
      )}
    </div>
  );
};

export const CharacterSelection = (props: CharacterSelectionProps) => {
  const { act } = useBackend();
  const { character_saves } = props;

  if (!character_saves || character_saves.length === 0) {
    return <div style={{ padding: '20px', textAlign: 'center', color: '#999' }}>No character saves available</div>;
  }

  return (
    <div
      style={{
        display: 'flex',
        gap: '8px',
        overflowX: 'auto',
        padding: '8px',
        maxWidth: '100%',
      }}
    >
      {character_saves.map((character) => (
        <div
          key={character.slot}
          onClick={() =>
            act('switch_character', {
              slot: character.slot,
            })
          }
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            padding: '8px',
            border: character.is_active ? '2px solid #00ccffff' : '1px solid #666',
            borderRadius: '4px',
            cursor: 'pointer',
            backgroundColor: character.is_active ? 'rgba(0, 110, 255, 0.1)' : 'rgba(0, 0, 0, 0.2)',
            minWidth: '80px',
            opacity: 1,
          }}
        >
          {/* Character headshot preview */}
          <DoubleBufferedHeadshot
            character={character}
            style={{
              position: 'relative',
              width: '64px',
              height: '48px',
              border: '1px solid #333',
              borderRadius: '2px',
              backgroundColor: '#222',
              marginBottom: '4px',
              overflow: 'hidden',
            }}
          />
          {/* Character name */}
          <div
            style={{
              fontSize: '11px',
              textAlign: 'center',
              wordBreak: 'break-word',
              lineHeight: '1.2',
              maxWidth: '76px',
            }}
          >
            {character.name || `Slot ${character.slot}`}
          </div>
        </div>
      ))}
    </div>
  );
};
