/**
 * Character preview component for the character creator
 * Backend sibling: code/modules/client/preference/character_creator/character_preview.dm
 */

import { useEffect, useState } from 'react';
import { Box, Stack } from 'tgui-core/components';

interface CharacterPreviewProps {
  has_preview: boolean;
  preview_timestamp: number;
}

// Double-buffered image component to prevent flickering
const DoubleBufferedImage = ({ src, alt, style }: { src: string; alt: string; style: React.CSSProperties }) => {
  const [currentSrc, setCurrentSrc] = useState(src);
  const [previousSrc, setPreviousSrc] = useState<string | null>(null);
  const [showPrevious, setShowPrevious] = useState(false);
  const [imageLoaded, setImageLoaded] = useState(false);

  useEffect(() => {
    // Always preload the image, even on initial render
    setImageLoaded(false);

    const img = new Image();
    img.onload = () => {
      if (src !== currentSrc) {
        setPreviousSrc(currentSrc);
        setShowPrevious(true);
        setCurrentSrc(src);
        // Hide previous image after new one loads
        setTimeout(() => {
          setShowPrevious(false);
          setPreviousSrc(null);
        }, 50);
      }
      setImageLoaded(true);
    };
    img.onerror = () => {
      // Image failed to load, don't show it
      setImageLoaded(false);
    };
    img.src = src;
  }, [src]);

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
      {/* Current image - only show if loaded */}
      {imageLoaded && (
        <img
          src={currentSrc}
          alt={alt}
          style={{
            width: '100%',
            height: '100%',
            imageRendering: 'pixelated',
          }}
        />
      )}
      {/* Loading placeholder */}
      {!imageLoaded && !showPrevious && (
        <div
          style={{
            width: '100%',
            height: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'rgba(255, 255, 255, 0.5)',
          }}
        >
          ...
        </div>
      )}
    </div>
  );
};

export const CharacterPreview = (props: CharacterPreviewProps) => {
  const { has_preview, preview_timestamp } = props;

  return (
    <Stack.Item>
      <Box height="140px" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        {has_preview ? (
          <Stack>
            <Stack.Item grow />
            <Stack.Item>
              <DoubleBufferedImage
                src={`char_preview_front_${preview_timestamp}.png`}
                alt="Character Front View"
                style={{
                  width: '128px',
                  height: '128px',
                  marginRight: '8px',
                }}
              />
            </Stack.Item>
            <Stack.Item>
              <DoubleBufferedImage
                src={`char_preview_side_${preview_timestamp}.png`}
                alt="Character Side View"
                style={{
                  width: '128px',
                  height: '128px',
                  marginLeft: '8px',
                }}
              />
            </Stack.Item>
            <Stack.Item grow />
          </Stack>
        ) : (
          <Box textAlign="center" color="label" p={2}>
            Loading...
          </Box>
        )}
      </Box>
    </Stack.Item>
  );
};
