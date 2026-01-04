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
  const [currentSrc, setCurrentSrc] = useState<string | null>(null);
  const [previousSrc, setPreviousSrc] = useState<string | null>(null);
  const [showPrevious, setShowPrevious] = useState(false);
  const [imageLoaded, setImageLoaded] = useState(false);
  const [retryCount, setRetryCount] = useState(0);

  useEffect(() => {
    // Check if we already have this image loaded
    if (currentSrc === src && imageLoaded) {
      return;
    }

    // Start loading immediately
    setImageLoaded(false);
    setRetryCount(0);

    const attemptLoad = (attempt = 0) => {
      const img = new Image();
      let isCancelled = false;

      img.onload = () => {
        if (isCancelled) return;

        if (currentSrc !== null && currentSrc !== src) {
          // We had a previous different image, show transition
          setPreviousSrc(currentSrc);
          setShowPrevious(true);
          setCurrentSrc(src);
          // Hide previous image after new one loads
          setTimeout(() => {
            if (!isCancelled) {
              setShowPrevious(false);
              setPreviousSrc(null);
            }
          }, 50);
        } else {
          // First load or same image, just set it
          setCurrentSrc(src);
        }
        setImageLoaded(true);
      };

      img.onerror = () => {
        if (isCancelled) return;
        // Image failed to load, retry up to 3 times with increasing delays
        if (attempt < 3) {
          const delay = Math.min(100 * Math.pow(2, attempt), 1000); // 100ms, 200ms, 400ms
          setTimeout(() => {
            if (!isCancelled) {
              setRetryCount(attempt + 1);
              attemptLoad(attempt + 1);
            }
          }, delay);
        } else {
          // Give up after 3 retries
          setImageLoaded(false);
        }
      };

      img.src = src;

      // Return cleanup function
      return () => {
        isCancelled = true;
      };
    };

    const cleanup = attemptLoad();

    // Cleanup function to prevent setState on unmounted component
    return cleanup;
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
      {imageLoaded && currentSrc && (
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
      {(!imageLoaded || !currentSrc) && !showPrevious && (
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
        {has_preview && preview_timestamp > 0 ? (
          <Stack>
            <Stack.Item grow />
            <Stack.Item>
              <DoubleBufferedImage
                key={`front-${preview_timestamp}`}
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
                key={`side-${preview_timestamp}`}
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
